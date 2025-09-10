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
