//
//  AttendanceServiceProtocol.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Protocol for attendance management service
public protocol AttendanceServiceProtocol: AnyObject {
    /// Check in for attendance
    func checkIn(at location: CLLocation?, beaconId: String?) async throws -> AttendanceSession
    
    /// Check out from attendance
    func checkOut(sessionId: String) async throws
    
    /// Get current active session
    func getCurrentSession() -> AttendanceSession?
    
    /// Get all sessions for user
    func getSessions(from startDate: Date, to endDate: Date) async throws -> [AttendanceSession]
    
    /// Sync offline sessions
    func syncOfflineSessions() async throws
    
    /// Validate beacon for attendance
    func validateBeacon(_ beaconId: String) async throws -> Bool
}

/// Model representing an attendance session
public struct AttendanceSession: Codable {
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
public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let timestamp: Date
    
    public init(latitude: Double, longitude: Double, accuracy: Double, timestamp: Date = Date()) {
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
}
