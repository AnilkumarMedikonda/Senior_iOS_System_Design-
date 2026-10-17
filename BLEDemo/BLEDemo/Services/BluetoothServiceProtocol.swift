//
//  BluetoothServiceProtocol.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import Combine

protocol BluetoothServiceProtocol: AnyObject {
    // Outputs
    var bluetoothState: AnyPublisher<BluetoothState, Never> { get }
    var isScanning: AnyPublisher<Bool, Never> { get }
    var discoveredDevices: AnyPublisher<[BLEDevice], Never> { get }
    var connectionState: AnyPublisher<ConnectionState, Never> { get }
    var heartRate: AnyPublisher<Int, Never> { get }

    // Inputs
    func startScan()
    func stopScan()
    func connect(to device: BLEDevice)
    func disconnect()
}
