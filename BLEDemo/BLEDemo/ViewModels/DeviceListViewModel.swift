//
//  DeviceListViewModel.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import Combine

@MainActor
final class DeviceListViewModel: ObservableObject {

    // MARK: - Output (View reads these)
    @Published private(set) var devices: [BLEDevice] = []
    @Published private(set) var statusText = "Starting Bluetooth..."
    @Published private(set) var isScanning = false
    @Published private(set) var isBluetoothReady = false
    @Published private(set) var connectingDeviceID: UUID?
    @Published var connectedDevice: BLEDevice?          // drives navigation

    var scanButtonTitle: String { isScanning ? "Stop" : "Scan" }

    // MARK: - Dependencies
    private let service: BluetoothServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: BluetoothServiceProtocol) {
        self.service = service
        bind()
    }

    // MARK: - Input (View calls these)
    func scanButtonTapped() {
        isScanning ? service.stopScan() : service.startScan()
    }

    func deviceTapped(_ device: BLEDevice) {
        guard connectingDeviceID == nil else { return }
        service.connect(to: device)
    }

    // MARK: - Binding
    private func bind() {
        service.bluetoothState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isBluetoothReady = (state == .poweredOn)
                self?.statusText = state.message
            }
            .store(in: &cancellables)

        service.isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)

        service.discoveredDevices
            .map { $0.sorted { $0.rssi > $1.rssi } }     // strongest signal first
            .receive(on: DispatchQueue.main)
            .assign(to: &$devices)

        service.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.handle(state) }
            .store(in: &cancellables)
    }

    private func handle(_ state: ConnectionState) {
        switch state {
        case .disconnected:
            connectingDeviceID = nil
            connectedDevice = nil
            statusText = "Disconnected"
        case .connecting(let device):
            connectingDeviceID = device.id
            statusText = "Connecting to \(device.name)..."
        case .connected(let device):
            connectingDeviceID = nil
            connectedDevice = device
            statusText = "Connected to \(device.name)"
        case .reconnecting(let device):
            statusText = "Reconnecting to \(device.name)..."
        case .failed(let message):
            connectingDeviceID = nil
            connectedDevice = nil
            statusText = message
        }
    }
}
