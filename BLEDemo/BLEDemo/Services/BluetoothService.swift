//
//  BluetoothService.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import Combine
import CoreBluetooth

final class BluetoothService: NSObject, BluetoothServiceProtocol {

    // MARK: - Subjects (internal state)
    private let stateSubject      = CurrentValueSubject<BluetoothState, Never>(.unknown)
    private let scanningSubject   = CurrentValueSubject<Bool, Never>(false)
    private let devicesSubject    = CurrentValueSubject<[BLEDevice], Never>([])
    private let connectionSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    private let heartRateSubject  = PassthroughSubject<Int, Never>()

    // MARK: - Public publishers
    var bluetoothState: AnyPublisher<BluetoothState, Never>   { stateSubject.eraseToAnyPublisher() }
    var isScanning: AnyPublisher<Bool, Never>                 { scanningSubject.eraseToAnyPublisher() }
    var discoveredDevices: AnyPublisher<[BLEDevice], Never>   { devicesSubject.eraseToAnyPublisher() }
    var connectionState: AnyPublisher<ConnectionState, Never> { connectionSubject.eraseToAnyPublisher() }
    var heartRate: AnyPublisher<Int, Never>                   { heartRateSubject.eraseToAnyPublisher() }

    // MARK: - Private
    private var centralManager: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]   // strong references (required!)
    private var connectedPeripheral: CBPeripheral?
    private var currentDevice: BLEDevice?
    private var userInitiatedDisconnect = false
    private var scanTimeoutWork: DispatchWorkItem?
    private var connectTimeoutWork: DispatchWorkItem?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Inputs
    func startScan() {
        guard centralManager.state == .poweredOn, !scanningSubject.value else { return }

        devicesSubject.send([])
        centralManager.scanForPeripherals(withServices: [BLEConstants.heartRateService], options: nil)
        scanningSubject.send(true)

        // Auto-stop scan to save battery
        let work = DispatchWorkItem { [weak self] in self?.stopScan() }
        scanTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEConstants.scanTimeout, execute: work)
    }

    func stopScan() {
        scanTimeoutWork?.cancel()
        guard scanningSubject.value else { return }
        centralManager.stopScan()
        scanningSubject.send(false)
    }

    func connect(to device: BLEDevice) {
        guard let peripheral = peripherals[device.id] else {
            connectionSubject.send(.failed("Device not found. Scan again."))
            return
        }
        stopScan()
        userInitiatedDisconnect = false
        currentDevice = device
        connectionSubject.send(.connecting(device))
        centralManager.connect(peripheral, options: nil)

        // connect() never times out by itself, so add our own timeout
        let work = DispatchWorkItem { [weak self] in
            guard let self, peripheral.state != .connected else { return }
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.currentDevice = nil
            self.connectionSubject.send(.failed("Connection timed out"))
        }
        connectTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEConstants.connectTimeout, execute: work)
    }

    func disconnect() {
        connectTimeoutWork?.cancel()
        userInitiatedDisconnect = true

        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)   // didDisconnect will fire
        } else if let device = currentDevice, let peripheral = peripherals[device.id] {
            centralManager.cancelPeripheralConnection(peripheral)   // cancel a pending connect
            currentDevice = nil
            connectionSubject.send(.disconnected)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state: BluetoothState
        switch central.state {
        case .poweredOn:    state = .poweredOn
        case .poweredOff:   state = .poweredOff
        case .unauthorized: state = .unauthorized
        case .unsupported:  state = .unsupported
        default:            state = .unknown
        }
        stateSubject.send(state)

        // Bluetooth turned off → reset everything
        if state != .poweredOn {
            scanningSubject.send(false)
            connectedPeripheral = nil
            currentDevice = nil
            connectionSubject.send(.disconnected)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral

        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Unknown Device"

        var devices = devicesSubject.value
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].rssi = RSSI.intValue
        } else {
            devices.append(BLEDevice(id: peripheral.identifier, name: name, rssi: RSSI.intValue))
        }
        devicesSubject.send(devices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectTimeoutWork?.cancel()
        connectedPeripheral = peripheral
        peripheral.delegate = self

        let device = currentDevice
            ?? BLEDevice(id: peripheral.identifier, name: peripheral.name ?? "Device", rssi: 0)
        currentDevice = device
        connectionSubject.send(.connected(device))

        peripheral.discoverServices([BLEConstants.heartRateService])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectTimeoutWork?.cancel()
        currentDevice = nil
        connectionSubject.send(.failed(error?.localizedDescription ?? "Failed to connect"))
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard peripheral.identifier == connectedPeripheral?.identifier else { return }

        if !userInitiatedDisconnect, let device = currentDevice {
            // Unexpected drop → auto-reconnect (iOS waits until the device is back in range)
            connectionSubject.send(.reconnecting(device))
            central.connect(peripheral, options: nil)
        } else {
            connectedPeripheral = nil
            currentDevice = nil
            connectionSubject.send(.disconnected)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([BLEConstants.heartRateMeasurement], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil else { return }
        for characteristic in service.characteristics ?? []
        where characteristic.uuid == BLEConstants.heartRateMeasurement {
            peripheral.setNotifyValue(true, for: characteristic)   // live updates
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil,
              characteristic.uuid == BLEConstants.heartRateMeasurement,
              let data = characteristic.value,
              let bpm = HeartRateParser.parse(data) else { return }

        heartRateSubject.send(bpm)
    }
}
