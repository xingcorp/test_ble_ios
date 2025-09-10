//
//  AttendanceModels.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Model representing an attendance session
public struct AttendanceSession: Codable, Equatable {
    public let id: String
    public let userId: String
    public let checkInTime: Date
    public var checkOutTime: Date?
    public let checkInLocation: Location?
    public var checkOutLocation: Location?
    public let beaconId: String?
    
    public var duration: TimeInterval? {
        guard let checkOutTime = checkOutTime else { return nil }
        return checkOutTime.timeIntervalSince(checkInTime)
    }
    
    public var isActive: Bool {
        return checkOutTime == nil
    }
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        checkInTime: Date = Date(),
        checkOutTime: Date? = nil,
        checkInLocation: Location? = nil,
        checkOutLocation: Location? = nil,
        beaconId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.checkInLocation = checkInLocation
        self.checkOutLocation = checkOutLocation
        self.beaconId = beaconId
    }
}

/// Location model for attendance
public struct Location: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let timestamp: Date
    
    public init(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
    
    public init(from clLocation: CLLocation) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.accuracy = clLocation.horizontalAccuracy
        self.timestamp = clLocation.timestamp
    }
    
    public func toCLLocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}

/// Attendance error types
public enum AttendanceError: LocalizedError, Equatable {
    case alreadyCheckedIn
    case notCheckedIn
    case sessionNotFound
    case invalidBeacon
    case locationUnavailable
    case networkError(String)
    case storageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyCheckedIn:
            return "You are already checked in"
        case .notCheckedIn:
            return "You are not checked in"
        case .sessionNotFound:
            return "Session not found"
        case .invalidBeacon:
            return "Invalid or unregistered beacon"
        case .locationUnavailable:
            return "Location services unavailable"
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
}
