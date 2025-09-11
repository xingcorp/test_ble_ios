//
//  AppConfiguration.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation

/// Environment types for different deployment stages
public enum Environment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
    
    /// Determine environment from build configuration or bundle
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        // Check for staging flag in Info.plist or use production as default
        if Bundle.main.object(forInfoDictionaryKey: "IS_STAGING") as? Bool == true {
            return .staging
        }
        return .production
        #endif
    }
}

/// Feature flags for controlled rollout
public struct FeatureFlags {
    public let isBeaconRangingEnabled: Bool
    public let isBackgroundSyncEnabled: Bool
    public let isOfflineModeEnabled: Bool
    public let isAnalyticsEnabled: Bool
    public let isCrashReportingEnabled: Bool
    public let isDebugMenuEnabled: Bool
    public let maxBeaconRange: Double // meters
    public let syncInterval: TimeInterval // seconds
    public let sessionTimeout: TimeInterval // seconds
    
    static let `default` = FeatureFlags(
        isBeaconRangingEnabled: true,
        isBackgroundSyncEnabled: true,
        isOfflineModeEnabled: true,
        isAnalyticsEnabled: true,
        isCrashReportingEnabled: true,
        isDebugMenuEnabled: false,
        maxBeaconRange: 20.0,
        syncInterval: 300, // 5 minutes
        sessionTimeout: 28800 // 8 hours
    )
}

/// API endpoints configuration
public struct APIConfiguration {
    public let baseURL: URL
    public let apiVersion: String
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let certificatePins: [String] // SHA256 pins for certificate pinning
    
    var attendanceEndpoint: URL {
        baseURL.appendingPathComponent("api/\(apiVersion)/attendance")
    }
    
    var beaconEndpoint: URL {
        baseURL.appendingPathComponent("api/\(apiVersion)/beacons")
    }
    
    var userEndpoint: URL {
        baseURL.appendingPathComponent("api/\(apiVersion)/users")
    }
}

/// Beacon configuration
public struct BeaconConfiguration {
    public let defaultUUID: String
    public let scanInterval: TimeInterval
    public let monitoringEnabled: Bool
    public let rangingEnabled: Bool
    public let backgroundScanningEnabled: Bool
}

/// Main app configuration
public final class AppConfiguration {
    
    // MARK: - Singleton
    public static let shared = AppConfiguration()
    
    // MARK: - Properties
    public let environment: Environment
    public let features: FeatureFlags
    public let api: APIConfiguration
    public let beacon: BeaconConfiguration
    public let appVersion: String
    public let buildNumber: String
    public let deviceId: String
    
    // Remote config cache
    private var remoteConfig: [String: Any] = [:]
    private let configQueue = DispatchQueue(label: "com.oxii.config", attributes: .concurrent)
    
    // MARK: - Initialization
    private init() {
        self.environment = Environment.current
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        self.buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        self.deviceId = Self.getOrCreateDeviceId()
        
        // Load configuration based on environment
        switch environment {
        case .development:
            self.features = FeatureFlags(
                isBeaconRangingEnabled: true,
                isBackgroundSyncEnabled: true,
                isOfflineModeEnabled: true,
                isAnalyticsEnabled: false,
                isCrashReportingEnabled: false,
                isDebugMenuEnabled: true,
                maxBeaconRange: 50.0, // Wider range for testing
                syncInterval: 60, // 1 minute for dev
                sessionTimeout: 3600 // 1 hour for dev
            )
            
            self.api = APIConfiguration(
                baseURL: URL(string: "https://dev-api.oxii-beacon.com")!,
                apiVersion: "v1",
                timeout: 30,
                maxRetries: 3,
                certificatePins: []
            )
            
            self.beacon = BeaconConfiguration(
                defaultUUID: "FDA50693-0000-0000-0000-290995101092", // Actual beacon UUID from scan logs
                scanInterval: 1.0,
                monitoringEnabled: true,
                rangingEnabled: true,
                backgroundScanningEnabled: true
            )
            
        case .staging:
            self.features = FeatureFlags(
                isBeaconRangingEnabled: true,
                isBackgroundSyncEnabled: true,
                isOfflineModeEnabled: true,
                isAnalyticsEnabled: true,
                isCrashReportingEnabled: true,
                isDebugMenuEnabled: true,
                maxBeaconRange: 20.0,
                syncInterval: 180, // 3 minutes
                sessionTimeout: 14400 // 4 hours
            )
            
            self.api = APIConfiguration(
                baseURL: URL(string: "https://staging-api.oxii-beacon.com")!,
                apiVersion: "v1",
                timeout: 20,
                maxRetries: 3,
                certificatePins: ["staging_pin_hash"]
            )
            
            self.beacon = BeaconConfiguration(
                defaultUUID: "550e8400-e29b-41d4-a716-446655440001", // Staging UUID
                scanInterval: 2.0,
                monitoringEnabled: true,
                rangingEnabled: true,
                backgroundScanningEnabled: true
            )
            
        case .production:
            self.features = FeatureFlags.default
            
            self.api = APIConfiguration(
                baseURL: URL(string: "https://api.oxii-beacon.com")!,
                apiVersion: "v1",
                timeout: 15,
                maxRetries: 2,
                certificatePins: ["prod_pin_hash_1", "prod_pin_hash_2"]
            )
            
            self.beacon = BeaconConfiguration(
                defaultUUID: "550e8400-e29b-41d4-a716-446655440002", // Production UUID
                scanInterval: 3.0,
                monitoringEnabled: true,
                rangingEnabled: true,
                backgroundScanningEnabled: true
            )
        }
        
        LoggerService.shared.info("🚀 App Configuration initialized - Environment: \(environment.rawValue)")
    }
    
    // MARK: - Validation
    
    /// Validate configuration
    public func validate() -> Bool {
        // Check if essential configurations are valid
        guard !api.baseURL.absoluteString.isEmpty else {
            LoggerService.shared.error("Invalid API base URL")
            return false
        }
        
        guard !beacon.defaultUUID.isEmpty else {
            LoggerService.shared.error("Invalid beacon UUID")
            return false
        }
        
        return true
    }
    
    // MARK: - Debug Info
    
    /// Get debug information about configuration
    public var debugInfo: String {
        """
        Configuration Debug Info:
        - Environment: \(environment.rawValue)
        - App Version: \(appVersion) (\(buildNumber))
        - Device ID: \(deviceId)
        - API Base URL: \(api.baseURL.absoluteString)
        - Beacon UUID: \(beacon.defaultUUID)
        - Features:
          • Beacon Ranging: \(features.isBeaconRangingEnabled)
          • Background Sync: \(features.isBackgroundSyncEnabled)
          • Offline Mode: \(features.isOfflineModeEnabled)
          • Analytics: \(features.isAnalyticsEnabled)
          • Debug Menu: \(features.isDebugMenuEnabled)
        """
    }
    
    // MARK: - Device ID Management
    
    private static func getOrCreateDeviceId() -> String {
        let key = "com.oxii.beacon.deviceId"
        if let deviceId = UserDefaults.standard.string(forKey: key) {
            return deviceId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: key)
            return newId
        }
    }
    
    // MARK: - Remote Config
    
    public func updateRemoteConfig(_ config: [String: Any]) {
        configQueue.async(flags: .barrier) {
            self.remoteConfig = config
            LoggerService.shared.info("Remote config updated with \(config.count) keys")
        }
    }
    
    public func getValue<T>(for key: String, default defaultValue: T) -> T {
        return configQueue.sync {
            remoteConfig[key] as? T ?? defaultValue
        }
    }
    
}

// MARK: - Configuration Extensions

public extension AppConfiguration {
    
    /// Check if specific feature is enabled
    func isFeatureEnabled(_ feature: String) -> Bool {
        // First check remote config
        if let remoteValue = getValue(for: "feature_\(feature)", default: nil as Bool?) {
            return remoteValue
        }
        
        // Fall back to local feature flags
        switch feature {
        case "beacon_ranging":
            return features.isBeaconRangingEnabled
        case "background_sync":
            return features.isBackgroundSyncEnabled
        case "offline_mode":
            return features.isOfflineModeEnabled
        case "analytics":
            return features.isAnalyticsEnabled
        case "crash_reporting":
            return features.isCrashReportingEnabled
        case "debug_menu":
            return features.isDebugMenuEnabled
        default:
            return false
        }
    }
}
