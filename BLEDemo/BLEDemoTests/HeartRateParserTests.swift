//
//  HeartRateParserTests.swift
//  BLEDemoTests
//
//  Created by Medikonda Anil kumar on 17/10/26.
//

import XCTest
@testable import BLEDemo

final class HeartRateParserTests: XCTestCase {
    func testParsesUInt8Value() {
        XCTAssertEqual(HeartRateParser.parse(Data([0x00, 72])), 72)
    }

    func testParsesUInt16Value() {
        XCTAssertEqual(HeartRateParser.parse(Data([0x01, 0x2C, 0x01])), 300)
    }

    func testReturnsNilForShortData() {
        XCTAssertNil(HeartRateParser.parse(Data([0x00])))
    }
}

@MainActor
final class ViewModelTests: XCTestCase {
    func testScanButtonCallsService() {
        let mock = MockBluetoothService()
        let viewModel = DeviceListViewModel(service: mock)

        viewModel.scanButtonTapped()

        XCTAssertEqual(mock.startScanCallCount, 1)
    }

    func testDetailStatsAreCalculated() {
        let device = BLEDevice(id: UUID(), name: "Test", rssi: -50)
        let viewModel = DeviceDetailViewModel(device: device, service: MockBluetoothService())

        for value in [60, 80, 100] { viewModel.add(value) }

        XCTAssertEqual(viewModel.minText, "60")
        XCTAssertEqual(viewModel.maxText, "100")
        XCTAssertEqual(viewModel.averageText, "80")
    }
}
