//
//  DeviceRowView.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import SwiftUI

struct DeviceRowView: View {
    let device: BLEDevice
    let isConnecting: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(device.rssi) dBm • \(device.signalDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isConnecting { ProgressView() }
        }
    }
}
