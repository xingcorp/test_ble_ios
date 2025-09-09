//
//  RSSISmoother.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Simple EWMA smoother for RSSI (higher is better)
public final class RSSISmoother {
    private var table: [String: Double] = [:] // key = beacon key
    private let alpha: Double
    private let window: Int
    
    public init(alpha: Double = 0.4, window: Int = 5) {
        self.alpha = alpha
        self.window = window
    }
    
    public func value(for beacon: CLBeacon) -> Double {
        let key = "\(beacon.uuid.uuidString)-\(beacon.major)-\(beacon.minor)"
        let rssi = Double(beacon.rssi == 0 ? -100 : beacon.rssi)
        let prev = table[key] ?? rssi
        let next = alpha * rssi + (1 - alpha) * prev
        table[key] = next
        return next
    }
    
    public func reset() {
        table.removeAll()
    }
}
