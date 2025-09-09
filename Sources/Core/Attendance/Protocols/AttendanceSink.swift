//
//  AttendanceSink.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

/// Protocol for handling attendance events
/// Can be implemented by NotificationSink, APISink, or CompositeSink
public protocol AttendanceSink: AnyObject {
    func handleCheckIn(sessionId: String, siteId: String, timestamp: Date)
    func handleCheckOut(sessionId: String, siteId: String, timestamp: Date, reason: String)
    func handleHeartbeat(sessionId: String, siteId: String, timestamp: Date)
}

/// Composite pattern for multiple sinks
public final class CompositeSink: AttendanceSink {
    private let sinks: [AttendanceSink]
    
    public init(sinks: [AttendanceSink]) {
        self.sinks = sinks
    }
    
    public func handleCheckIn(sessionId: String, siteId: String, timestamp: Date) {
        sinks.forEach { $0.handleCheckIn(sessionId: sessionId, siteId: siteId, timestamp: timestamp) }
    }
    
    public func handleCheckOut(sessionId: String, siteId: String, timestamp: Date, reason: String) {
        sinks.forEach { $0.handleCheckOut(sessionId: sessionId, siteId: siteId, timestamp: timestamp, reason: reason) }
    }
    
    public func handleHeartbeat(sessionId: String, siteId: String, timestamp: Date) {
        sinks.forEach { $0.handleHeartbeat(sessionId: sessionId, siteId: siteId, timestamp: timestamp) }
    }
}
