//
//  TelemetryEvent.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public enum EventType: String, Codable {
    case checkIn = "check_in"
    case checkOut = "check_out"
    case heartbeat = "heartbeat"
    case regionEnter = "region_enter"
    case regionExit = "region_exit"
    case rangingStart = "ranging_start"
    case rangingEnd = "ranging_end"
    case softExitStart = "soft_exit_start"
    case softExitCancel = "soft_exit_cancel"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    case error = "error"
    case appLifecycle = "app_lifecycle"
}

public enum EventSeverity: String, Codable {
    case verbose = "verbose"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

public struct TelemetryEvent: Codable {
    public let id: String
    public let type: EventType
    public let severity: EventSeverity
    public let timestamp: Date
    public let sessionId: String?
    public let siteId: String?
    public let metadata: [String: String]
    public let metrics: [String: Double]?
    
    public init(
        type: EventType,
        severity: EventSeverity = .info,
        sessionId: String? = nil,
        siteId: String? = nil,
        metadata: [String: String] = [:],
        metrics: [String: Double]? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.severity = severity
        self.timestamp = Date()
        self.sessionId = sessionId
        self.siteId = siteId
        self.metadata = metadata
        self.metrics = metrics
    }
}

// MARK: - Metric Keys
public struct MetricKey {
    public static let rssi = "rssi"
    public static let beaconCount = "beacon_count"
    public static let rangingDuration = "ranging_duration_ms"
    public static let exitLatency = "exit_latency_seconds"
    public static let batteryLevel = "battery_level"
    public static let memoryUsage = "memory_usage_mb"
    public static let cpuUsage = "cpu_usage_percent"
}
