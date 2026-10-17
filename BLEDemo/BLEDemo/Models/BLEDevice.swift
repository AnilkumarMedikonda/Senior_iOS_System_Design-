//
//  BLEDevice.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation

struct BLEDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    var rssi: Int

    var signalDescription: String {
        switch rssi {
        case -60...0:      return "Excellent"
        case -75 ..< -60:  return "Good"
        case -90 ..< -75:  return "Fair"
        default:           return "Weak"
        }
    }
}
