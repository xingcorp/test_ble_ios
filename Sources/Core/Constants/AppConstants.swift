//
//  AppConstants.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Centralized constants for the entire app
public enum AppConstants {
    
    // MARK: - iBeacon
    public enum Beacon {
        public static let defaultUUID = "FDA50693-0000-0000-0000-290995101092"
        public static let maxRegions = 20 // iOS limit
        public static let rangingDuration: TimeInterval = 8.0
        public static let rangingDebounceInterval: TimeInterval = 30.0
        public static let rssiThresholdWeak = -85
        public static let rssiThresholdVeryWeak = -95
        public static let rssiWindowSize = 5
    }
    
    // MARK: - Timing
    public enum Timing {
        public static let softExitGracePeriod: TimeInterval = 45.0
        public static let heartbeatMinInterval: TimeInterval = 60.0
        public static let heartbeatMaxInterval: TimeInterval = 300.0
        public static let networkTimeout: TimeInterval = 30.0
        public static let retryDelay: TimeInterval = 2.0
        public static let maxRetryAttempts = 3
    }
    
    // MARK: - Storage
    public enum Storage {
        public static let activeSessionKey = "active_session"
        public static let userIdKey = "user_id"
        public static let configurationKey = "app_configuration"
        public static let telemetryFolderName = "Telemetry"
        public static let maxTelemetryEvents = 1000
    }
    
    // MARK: - Notification
    public enum Notification {
        public static let categoryAttendance = "ATTENDANCE"
        public static let actionViewDetails = "VIEW_DETAILS"
        public static let notificationDelay: TimeInterval = 0.1
    }
    
    // MARK: - Background Task
    public enum BackgroundTask {
        public static let heartbeatIdentifier = "com.attendance.beacon.heartbeat"
        public static let syncIdentifier = "com.attendance.beacon.sync"
    }
    
    // MARK: - API
    public enum API {
        public static let baseURL = "https://api.example.com"
        public static let checkInPath = "/attendance/check-in"
        public static let checkOutPath = "/attendance/check-out"
        public static let heartbeatPath = "/attendance/heartbeat"
        public static let configPath = "/config/sites"
    }
    
    // MARK: - Battery
    public enum Battery {
        public static let lowThreshold: Float = 0.2
        public static let criticalThreshold: Float = 0.1
    }
    
    // MARK: - Debug
    public enum Debug {
        #if DEBUG
        public static let isEnabled = true
        #else
        public static let isEnabled = false
        #endif
        
        public static let mockLocationEnabled = false
        public static let verboseLogging = Debug.isEnabled
    }
}
