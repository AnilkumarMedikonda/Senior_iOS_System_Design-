//
//  MockBluetoothService.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import Combine

/// Fake service for SwiftUI previews and unit tests. No Bluetooth needed.
final class MockBluetoothService: BluetoothServiceProtocol {
    let stateSubject      = CurrentValueSubject<BluetoothState, Never>(.poweredOn)
    let scanningSubject   = CurrentValueSubject<Bool, Never>(false)
    let devicesSubject    = CurrentValueSubject<[BLEDevice], Never>([])
    let connectionSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    let heartRateSubject  = PassthroughSubject<Int, Never>()

    var bluetoothState: AnyPublisher<BluetoothState, Never>   { stateSubject.eraseToAnyPublisher() }
    var isScanning: AnyPublisher<Bool, Never>                 { scanningSubject.eraseToAnyPublisher() }
    var discoveredDevices: AnyPublisher<[BLEDevice], Never>   { devicesSubject.eraseToAnyPublisher() }
    var connectionState: AnyPublisher<ConnectionState, Never> { connectionSubject.eraseToAnyPublisher() }
    var heartRate: AnyPublisher<Int, Never>                   { heartRateSubject.eraseToAnyPublisher() }

    private(set) var startScanCallCount = 0
    private var timer: Timer?

    func startScan() {
        startScanCallCount += 1
        scanningSubject.send(true)
        devicesSubject.send([
            BLEDevice(id: UUID(), name: "Pulse Monitor A", rssi: -55),
            BLEDevice(id: UUID(), name: "Pulse Monitor B", rssi: -80)
        ])
    }

    func stopScan() {
        scanningSubject.send(false)
    }

    func connect(to device: BLEDevice) {
        scanningSubject.send(false)
        connectionSubject.send(.connected(device))
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.heartRateSubject.send(Int.random(in: 60...100))
        }
    }

    func disconnect() {
        timer?.invalidate()
        connectionSubject.send(.disconnected)
    }
}
