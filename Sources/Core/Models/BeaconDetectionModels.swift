//
//  BeaconDetectionModels.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Model representing a detected beacon with its properties
public struct DetectedBeacon: Codable {
    public let uuid: String
    public let major: Int
    public let minor: Int
    public let rssi: Int
    public let distance: Double
    public let lastSeen: Date
    
    public init(uuid: String, major: Int, minor: Int, rssi: Int, distance: Double, lastSeen: Date) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.rssi = rssi
        self.distance = distance
        self.lastSeen = lastSeen
    }
}
