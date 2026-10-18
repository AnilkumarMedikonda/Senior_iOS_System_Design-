//
//  BluetoothState.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation

enum BluetoothState {
    case unknown, poweredOn, poweredOff, unauthorized, unsupported

    var message: String {
        switch self {
        case .unknown:      return "Starting Bluetooth..."
        case .poweredOn:    return "Bluetooth is ON. Tap Scan."
        case .poweredOff:   return "Bluetooth is OFF"
        case .unauthorized: return "Bluetooth permission denied"
        case .unsupported:  return "Bluetooth not supported (Simulator?)"
        }
    }
}
