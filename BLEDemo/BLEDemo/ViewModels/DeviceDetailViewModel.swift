//
//  DeviceDetailViewModel.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import Combine

@MainActor
final class DeviceDetailViewModel: ObservableObject {

    let device: BLEDevice

    // MARK: - Output
    @Published private(set) var heartRate: Int?
    @Published private(set) var readings: [Int] = []
    @Published private(set) var connectionText = "Connected"
    @Published private(set) var isReconnecting = false

    var heartRateText: String { heartRate.map(String.init) ?? "--" }
    var minText: String       { readings.min().map(String.init) ?? "--" }
    var maxText: String       { readings.max().map(String.init) ?? "--" }
    var averageText: String {
        guard !readings.isEmpty else { return "--" }
        return String(readings.reduce(0, +) / readings.count)
    }

    // MARK: - Dependencies
    private let service: BluetoothServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let maxReadings = 30

    init(device: BLEDevice, service: BluetoothServiceProtocol) {
        self.device = device
        self.service = service
        bind()
    }

    // MARK: - Input
    func disconnectTapped() {
        service.disconnect()
    }

    func add(_ value: Int) {
        heartRate = value
        readings.append(value)
        if readings.count > maxReadings { readings.removeFirst() }
    }

    // MARK: - Binding
    private func bind() {
        service.heartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bpm in self?.add(bpm) }
            .store(in: &cancellables)

        service.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .connected:
                    self?.connectionText = "Connected"
                    self?.isReconnecting = false
                case .reconnecting:
                    self?.connectionText = "Connection lost. Reconnecting..."
                    self?.isReconnecting = true
                default:
                    self?.connectionText = "Disconnected"
                    self?.isReconnecting = false
                }
            }
            .store(in: &cancellables)
    }
}
