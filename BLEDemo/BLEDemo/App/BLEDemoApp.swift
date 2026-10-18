//
//  BLEDemoApp.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import SwiftUI

@main
struct BLEDemoApp: App {
    // One shared service for the whole app.
    // Swap in MockBluetoothService() to run without a real device.
    private let bluetoothService: BluetoothServiceProtocol = BluetoothService()

    var body: some Scene {
        WindowGroup {
            DeviceListView(service: bluetoothService)
        }
    }
}
