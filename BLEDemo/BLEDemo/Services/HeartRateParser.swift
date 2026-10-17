//
//  HeartRateParser.swift
//  BLEDemo
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import Foundation

enum HeartRateParser {
    /// Byte 0 = flags. Bit 0: 0 → value is UInt8, 1 → value is UInt16 (little-endian).
    static func parse(_ data: Data) -> Int? {
        let bytes = [UInt8](data)
        guard bytes.count >= 2 else { return nil }

        if bytes[0] & 0x01 == 0 {
            return Int(bytes[1])
        }
        guard bytes.count >= 3 else { return nil }
        return Int(bytes[1]) | (Int(bytes[2]) << 8)
    }
}
