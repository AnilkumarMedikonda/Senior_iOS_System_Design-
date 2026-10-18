//
//  BLEConstants.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation
import CoreBluetooth

enum BLEConstants {
    // Replace with your medical device's UUIDs
    static let heartRateService     = CBUUID(string: "180D")
    static let heartRateMeasurement = CBUUID(string: "2A37")

    static let scanTimeout: TimeInterval    = 10
    static let connectTimeout: TimeInterval = 10
}
