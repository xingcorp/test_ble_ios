//
//  DiagnosticModels.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Enterprise-grade diagnostic data models for beacon monitoring
//

import Foundation
import CoreLocation
import CoreBluetooth

// MARK: - Diagnostic Issue

/// Represents a diagnostic issue detected in the beacon monitoring system
public struct DiagnosticIssue: Codable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let category: DiagnosticCategory
    public let severity: DiagnosticSeverity
    public let title: String
    public let description: String
    public let context: [String: String] // Simplified for Codable
    public let suggestedActions: [String]
    
    public init(
        category: DiagnosticCategory,
        severity: DiagnosticSeverity,
        title: String,
        description: String,
        context: [String: String] = [:],
        suggestedActions: [String] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.category = category
        self.severity = severity
        self.title = title
        self.description = description
        self.context = context
        self.suggestedActions = suggestedActions
    }
    
    /// User-friendly description for display
    public var displayDescription: String {
        return "\(title): \(description)"
    }
    
    /// Severity emoji for UI display
    public var severityEmoji: String {
        switch severity {
        case .critical: return "🚨"
        case .warning: return "⚠️"
        case .info: return "ℹ️"
        }
    }
}

// MARK: - Diagnostic Categories

public enum DiagnosticCategory: String, Codable, CaseIterable {
    case bluetoothIssue = "bluetooth"
    case permissionIssue = "permission"
    case systemIssue = "system"
    case beaconIssue = "beacon"
    case networkIssue = "network"
    case configurationIssue = "configuration"
    
    public var displayName: String {
        switch self {
        case .bluetoothIssue: return "Bluetooth"
        case .permissionIssue: return "Permissions"
        case .systemIssue: return "System"
        case .beaconIssue: return "Beacon"
        case .networkIssue: return "Network"
        case .configurationIssue: return "Configuration"
        }
    }
    
    public var icon: String {
        switch self {
        case .bluetoothIssue: return "📶"
        case .permissionIssue: return "🔐"
        case .systemIssue: return "⚙️"
        case .beaconIssue: return "📡"
        case .networkIssue: return "🌐"
        case .configurationIssue: return "⚙️"
        }
    }
}

public enum DiagnosticSeverity: String, Codable, CaseIterable, Comparable {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
    
    // Comparable implementation for sorting
    public static func < (lhs: DiagnosticSeverity, rhs: DiagnosticSeverity) -> Bool {
        let order: [DiagnosticSeverity] = [.info, .warning, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - System Health Models

public struct SystemHealthReport: Codable {
    public let timestamp: Date
    public let sessionId: UUID
    public let overallHealth: HealthScore
    public let bluetoothStatus: BluetoothStatus
    public let permissionStatus: PermissionStatus
    public let batteryImpact: BatteryImpactMetrics
    public let backgroundStatus: BackgroundExecutionStatus
    public let beaconMonitoringStatus: BeaconMonitoringStatus
    public let systemInfo: SystemInfo
    public let issues: [DiagnosticIssue]
    
    public init(
        overallHealth: HealthScore,
        bluetoothStatus: BluetoothStatus,
        permissionStatus: PermissionStatus,
        batteryImpact: BatteryImpactMetrics,
        backgroundStatus: BackgroundExecutionStatus,
        beaconMonitoringStatus: BeaconMonitoringStatus,
        systemInfo: SystemInfo,
        issues: [DiagnosticIssue] = []
    ) {
        self.timestamp = Date()
        self.sessionId = UUID()
        self.overallHealth = overallHealth
        self.bluetoothStatus = bluetoothStatus
        self.permissionStatus = permissionStatus
        self.batteryImpact = batteryImpact
        self.backgroundStatus = backgroundStatus
        self.beaconMonitoringStatus = beaconMonitoringStatus
        self.systemInfo = systemInfo
        self.issues = issues
    }
    
    /// Export as JSON string for debugging
    public func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

public enum HealthScore: String, Codable {
    case excellent = "excellent"    // 90-100%
    case good = "good"             // 70-89%
    case fair = "fair"             // 50-69%
    case poor = "poor"             // 0-49%
    
    public var percentage: Int {
        switch self {
        case .excellent: return 95
        case .good: return 80
        case .fair: return 60
        case .poor: return 30
        }
    }
    
    public var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    public var emoji: String {
        switch self {
        case .excellent: return "🟢"
        case .good: return "🔵"
        case .fair: return "🟡"
        case .poor: return "🔴"
        }
    }
}

public struct BluetoothStatus: Codable {
    public let isAvailable: Bool
    public let state: String // CBManagerState raw value
    public let lastUpdateTime: Date
    
    public init(isAvailable: Bool, state: CBManagerState) {
        self.isAvailable = isAvailable
        self.state = state.description
        self.lastUpdateTime = Date()
    }
    
    public var displayStatus: String {
        return isAvailable ? "✅ Available (\(state))" : "❌ Unavailable (\(state))"
    }
}

public struct PermissionStatus: Codable {
    public let locationAuthorization: String // CLAuthorizationStatus
    public let bluetoothAuthorization: String
    public let backgroundRefreshStatus: String
    public let notificationAuthorization: String
    public let isOptimalConfiguration: Bool
    
    public init(
        locationAuth: CLAuthorizationStatus,
        bluetoothAuth: String = "Unknown",
        backgroundRefresh: String = "Unknown",
        notificationAuth: String = "Unknown"
    ) {
        self.locationAuthorization = locationAuth.description
        self.bluetoothAuthorization = bluetoothAuth
        self.backgroundRefreshStatus = backgroundRefresh
        self.notificationAuthorization = notificationAuth
        
        // Optimal: Always location + Background refresh enabled
        self.isOptimalConfiguration = locationAuth == .authorizedAlways
    }
    
    public var displaySummary: String {
        let status = isOptimalConfiguration ? "✅ Optimal" : "⚠️ Needs Attention"
        return "\(status) - Location: \(locationAuthorization)"
    }
}

public struct BatteryImpactMetrics: Codable {
    public let estimatedImpactPercentage: Double
    public let rangingSessionsCount: Int
    public let backgroundTasksCount: Int
    public let lastMeasurementTime: Date
    
    public init(
        impactPercentage: Double = 0.0,
        rangingSessions: Int = 0,
        backgroundTasks: Int = 0
    ) {
        self.estimatedImpactPercentage = impactPercentage
        self.rangingSessionsCount = rangingSessions
        self.backgroundTasksCount = backgroundTasks
        self.lastMeasurementTime = Date()
    }
    
    public var impactLevel: String {
        switch estimatedImpactPercentage {
        case 0..<1: return "🟢 Minimal"
        case 1..<5: return "🟡 Moderate"
        default: return "🔴 High"
        }
    }
}

public struct BackgroundExecutionStatus: Codable {
    public let backgroundAppRefreshEnabled: Bool
    public let backgroundTasksScheduled: Int
    public let lastBackgroundExecution: Date?
    public let backgroundExecutionTime: TimeInterval
    
    public init(
        refreshEnabled: Bool,
        tasksScheduled: Int = 0,
        lastExecution: Date? = nil,
        executionTime: TimeInterval = 0
    ) {
        self.backgroundAppRefreshEnabled = refreshEnabled
        self.backgroundTasksScheduled = tasksScheduled
        self.lastBackgroundExecution = lastExecution
        self.backgroundExecutionTime = executionTime
    }
    
    public var displayStatus: String {
        let refreshStatus = backgroundAppRefreshEnabled ? "✅ Enabled" : "❌ Disabled"
        return "Background Refresh: \(refreshStatus)"
    }
}

public struct BeaconMonitoringStatus: Codable {
    public let regionsMonitored: Int
    public let regionsActive: Int
    public let lastCallbackTime: Date?
    public let rangingActive: Bool
    public let monitoringErrors: [String]
    
    public init(
        monitored: Int,
        active: Int = 0,
        lastCallback: Date? = nil,
        ranging: Bool = false,
        errors: [String] = []
    ) {
        self.regionsMonitored = monitored
        self.regionsActive = active
        self.lastCallbackTime = lastCallback
        self.rangingActive = ranging
        self.monitoringErrors = errors
    }
    
    public var healthStatus: String {
        if monitoringErrors.isEmpty && regionsActive > 0 {
            return "🟢 Healthy"
        } else if regionsMonitored > 0 && regionsActive == 0 {
            return "🟡 Monitoring but No Activity"
        } else {
            return "🔴 Issues Detected"
        }
    }
}

public struct SystemInfo: Codable {
    public let iosVersion: String
    public let deviceModel: String
    public let appVersion: String
    public let buildNumber: String
    public let timestamp: Date
    
    public init() {
        self.iosVersion = UIDevice.current.systemVersion
        self.deviceModel = UIDevice.current.model
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.timestamp = Date()
    }
    
    public var displaySummary: String {
        return "\(deviceModel) - iOS \(iosVersion) - App \(appVersion)(\(buildNumber))"
    }
}

// MARK: - Helper Extensions

extension CBManagerState {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Unknown"
        }
    }
}

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}