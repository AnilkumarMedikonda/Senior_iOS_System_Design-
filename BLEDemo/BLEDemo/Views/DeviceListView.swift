//
//  DeviceListView.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import SwiftUI

struct DeviceListView: View {
    @StateObject private var viewModel: DeviceListViewModel
    private let service: BluetoothServiceProtocol

    init(service: BluetoothServiceProtocol) {
        self.service = service
        _viewModel = StateObject(wrappedValue: DeviceListViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    HStack {
                        Text(viewModel.statusText)
                        Spacer()
                        if viewModel.isScanning { ProgressView() }
                    }
                }

                Section("Nearby Devices") {
                    if viewModel.devices.isEmpty {
                        Text("No devices yet. Tap Scan.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.devices) { device in
                        Button {
                            viewModel.deviceTapped(device)
                        } label: {
                            DeviceRowView(device: device,
                                          isConnecting: viewModel.connectingDeviceID == device.id)
                        }
                    }
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                Button(viewModel.scanButtonTitle) {
                    viewModel.scanButtonTapped()
                }
                .disabled(!viewModel.isBluetoothReady)
            }
            .navigationDestination(item: $viewModel.connectedDevice) { device in
                DeviceDetailView(device: device, service: service)
            }
        }
    }
}

#Preview {
    DeviceListView(service: MockBluetoothService())
}
