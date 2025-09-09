//
//  RSSISmootherTests.swift
//  BeaconAttendanceTests
//
//  Created by Senior iOS Team
//

import XCTest
import CoreLocation
@testable import BeaconAttendance

final class RSSISmootherTests: XCTestCase {
    
    func testEWMAStabilizes() {
        let smoother = RSSISmoother(alpha: 0.5, window: 5)
        
        // Synthetic values simulating RSSI fluctuations
        let values: [Int] = [-80, -82, -60, -58, -57]
        var lastSmoothed = -100.0
        
        for rssi in values {
            let beacon = MockBeacon(rssi: rssi)
            lastSmoothed = smoother.value(for: beacon)
        }
        
        // After smoothing, value should stabilize around -60 range
        XCTAssertGreaterThan(lastSmoothed, -70)
        XCTAssertLessThan(lastSmoothed, -50)
    }
    
    func testSmoothingReducesNoise() {
        let smoother = RSSISmoother(alpha: 0.3, window: 5)
        let beacon1 = MockBeacon(rssi: -90)
        let beacon2 = MockBeacon(rssi: -50) // Big jump
        
        _ = smoother.value(for: beacon1)
        let smoothed = smoother.value(for: beacon2)
        
        // Smoothing should reduce the impact of sudden jumps
        XCTAssertLessThan(smoothed, -60) // Not immediately jumping to -50
    }
}

// Mock beacon for testing
private class MockBeacon: CLBeacon {
    private let _rssi: Int
    private let _uuid = UUID()
    private let _major = NSNumber(value: 1)
    private let _minor = NSNumber(value: 1)
    
    init(rssi: Int) {
        self._rssi = rssi
        super.init()
    }
    
    override var rssi: Int { return _rssi }
    override var uuid: UUID { return _uuid }
    override var major: NSNumber { return _major }
    override var minor: NSNumber { return _minor }
}
