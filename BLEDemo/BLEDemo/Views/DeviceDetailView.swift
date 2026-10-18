//
//  DeviceDetailView.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import SwiftUI

struct DeviceDetailView: View {
    @StateObject private var viewModel: DeviceDetailViewModel

    init(device: BLEDevice, service: BluetoothServiceProtocol) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device, service: service))
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(viewModel.connectionText)
                .font(.subheadline)
                .foregroundStyle(viewModel.isReconnecting ? Color.orange : Color.green)

            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)
                Text(viewModel.heartRateText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                Text("BPM")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 40) {
                stat(title: "Min", value: viewModel.minText)
                stat(title: "Avg", value: viewModel.averageText)
                stat(title: "Max", value: viewModel.maxText)
            }

            Spacer()

            Button("Disconnect", role: .destructive) {
                viewModel.disconnectTapped()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle(viewModel.device.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.disconnectTapped()     // Back button also disconnects
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
}
