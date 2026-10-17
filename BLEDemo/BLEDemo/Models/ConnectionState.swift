//
//  ConnectionState.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting(BLEDevice)
    case connected(BLEDevice)
    case reconnecting(BLEDevice)
    case failed(String)
}
