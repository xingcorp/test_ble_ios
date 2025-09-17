//
//  LocationError.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Purpose: Enterprise-grade error handling for location services
//

import Foundation
import CoreLocation

// MARK: - Location Service Errors

/// Comprehensive error handling for location and beacon operations
/// Provides context information and recovery suggestions for enterprise applications
public enum LocationError: Error, CaseIterable, Equatable {
    
    // MARK: - Permission Errors
    
    case permissionDenied
    case permissionRestricted
    case permissionNotDetermined
    case backgroundExecutionDenied
    
    // MARK: - Service Availability Errors
    
    case locationServicesDisabled
    case beaconRangingUnavailable
    case beaconMonitoringUnavailable
    case significantLocationChangeUnavailable
    
    // MARK: - Operation Errors
    
    case timeout(operation: String, duration: TimeInterval)
    case rangingFailed(region: String, underlyingError: Error?)
    case monitoringFailed(region: String, underlyingError: Error?)
    case locationUpdateFailed(underlyingError: Error?)
    case significantLocationChangeFailed(underlyingError: Error?)
    
    // MARK: - Resource Errors
    
    case batteryOptimizationActive
    case memoryPressure
    case networkUnavailable
    case storageUnavailable
    
    // MARK: - Configuration Errors
    
    case invalidConfiguration(reason: String)
    case unsupportedDevice
    case regionLimitExceeded
    
    // MARK: - System Errors
    
    case systemError(underlyingError: Error)
    case unknown(code: Int, description: String)
    
    // MARK: - CaseIterable Implementation
    
    public static var allCases: [LocationError] {
        return [
            .permissionDenied,
            .permissionRestricted,
            .permissionNotDetermined,
            .backgroundExecutionDenied,
            .locationServicesDisabled,
            .beaconRangingUnavailable,
            .beaconMonitoringUnavailable,
            .significantLocationChangeUnavailable,
            .timeout(operation: "sample", duration: 10.0),
            .rangingFailed(region: "sample", underlyingError: nil),
            .monitoringFailed(region: "sample", underlyingError: nil),
            .locationUpdateFailed(underlyingError: nil),
            .significantLocationChangeFailed(underlyingError: nil),
            .batteryOptimizationActive,
            .memoryPressure,
            .networkUnavailable,
            .storageUnavailable,
            .invalidConfiguration(reason: "sample"),
            .unsupportedDevice,
            .regionLimitExceeded,
            .systemError(underlyingError: NSError(domain: "sample", code: 0)),
            .unknown(code: 0, description: "sample")
        ]
    }
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.permissionRestricted, .permissionRestricted),
             (.permissionNotDetermined, .permissionNotDetermined),
             (.backgroundExecutionDenied, .backgroundExecutionDenied),
             (.locationServicesDisabled, .locationServicesDisabled),
             (.beaconRangingUnavailable, .beaconRangingUnavailable),
             (.beaconMonitoringUnavailable, .beaconMonitoringUnavailable),
             (.significantLocationChangeUnavailable, .significantLocationChangeUnavailable),
             (.batteryOptimizationActive, .batteryOptimizationActive),
             (.memoryPressure, .memoryPressure),
             (.networkUnavailable, .networkUnavailable),
             (.storageUnavailable, .storageUnavailable),
             (.unsupportedDevice, .unsupportedDevice),
             (.regionLimitExceeded, .regionLimitExceeded):
            return true
        case let (.timeout(op1, dur1), .timeout(op2, dur2)):
            return op1 == op2 && dur1 == dur2
        case let (.rangingFailed(region1, _), .rangingFailed(region2, _)):
            return region1 == region2
        case let (.monitoringFailed(region1, _), .monitoringFailed(region2, _)):
            return region1 == region2
        case let (.invalidConfiguration(reason1), .invalidConfiguration(reason2)):
            return reason1 == reason2
        case let (.unknown(code1, desc1), .unknown(code2, desc2)):
            return code1 == code2 && desc1 == desc2
        default:
            return false
        }
    }
}

// MARK: - Error Information

extension LocationError {
    
    /// Error domain for NSError bridging
    public static let domain = "LocationErrorDomain"
    
    /// Unique error code for each case
    public var code: Int {
        switch self {
        case .permissionDenied: return 1001
        case .permissionRestricted: return 1002
        case .permissionNotDetermined: return 1003
        case .backgroundExecutionDenied: return 1004
        case .locationServicesDisabled: return 2001
        case .beaconRangingUnavailable: return 2002
        case .beaconMonitoringUnavailable: return 2003
        case .significantLocationChangeUnavailable: return 2004
        case .timeout: return 3001
        case .rangingFailed: return 3002
        case .monitoringFailed: return 3003
        case .locationUpdateFailed: return 3004
        case .significantLocationChangeFailed: return 3005
        case .batteryOptimizationActive: return 4001
        case .memoryPressure: return 4002
        case .networkUnavailable: return 4003
        case .storageUnavailable: return 4004
        case .invalidConfiguration: return 5001
        case .unsupportedDevice: return 5002
        case .regionLimitExceeded: return 5003
        case .systemError: return 6001
        case .unknown: return 9999
        }
    }
    
    /// Human-readable error description
    public var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .permissionRestricted:
            return "Location access is restricted by device policy."
        case .permissionNotDetermined:
            return "Location permission not requested. Please allow location access."
        case .backgroundExecutionDenied:
            return "Background location updates denied. Enable 'Always' location access for full functionality."
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable in Settings > Privacy & Security > Location Services."
        case .beaconRangingUnavailable:
            return "Beacon ranging is not available on this device."
        case .beaconMonitoringUnavailable:
            return "Beacon monitoring is not available on this device."
        case .significantLocationChangeUnavailable:
            return "Significant location change monitoring is not available on this device."
        case let .timeout(operation, duration):
            return "Operation '\(operation)' timed out after \(duration) seconds."
        case let .rangingFailed(region, underlyingError):
            let baseMessage = "Failed to start ranging for region '\(region)'"
            if let error = underlyingError {
                return "\(baseMessage): \(error.localizedDescription)"
            }
            return baseMessage
        case let .monitoringFailed(region, underlyingError):
            let baseMessage = "Failed to start monitoring region '\(region)'"
            if let error = underlyingError {
                return "\(baseMessage): \(error.localizedDescription)"
            }
            return baseMessage
        case let .locationUpdateFailed(underlyingError):
            let baseMessage = "Location update failed"
            if let error = underlyingError {
                return "\(baseMessage): \(error.localizedDescription)"
            }
            return baseMessage
        case let .significantLocationChangeFailed(underlyingError):
            let baseMessage = "Significant location change monitoring failed"
            if let error = underlyingError {
                return "\(baseMessage): \(error.localizedDescription)"
            }
            return baseMessage
        case .batteryOptimizationActive:
            return "Battery optimization is limiting location services. Consider disabling battery optimization for this app."
        case .memoryPressure:
            return "System memory pressure is affecting location services."
        case .networkUnavailable:
            return "Network connection required for this operation."
        case .storageUnavailable:
            return "Local storage is unavailable for caching location data."
        case let .invalidConfiguration(reason):
            return "Invalid location service configuration: \(reason)"
        case .unsupportedDevice:
            return "Location services are not supported on this device."
        case .regionLimitExceeded:
            return "Maximum number of monitored regions exceeded (iOS limit: 20 regions)."
        case let .systemError(underlyingError):
            return "System error: \(underlyingError.localizedDescription)"
        case let .unknown(code, description):
            return "Unknown error (\(code)): \(description)"
        }
    }
    
    /// Technical error description for debugging
    public var debugDescription: String {
        switch self {
        case .permissionDenied:
            return "CLAuthorizationStatus: denied"
        case .permissionRestricted:
            return "CLAuthorizationStatus: restricted"
        case .permissionNotDetermined:
            return "CLAuthorizationStatus: notDetermined"
        case .backgroundExecutionDenied:
            return "allowsBackgroundLocationUpdates: false or WhenInUse permission"
        case .locationServicesDisabled:
            return "CLLocationManager.locationServicesEnabled(): false"
        case .beaconRangingUnavailable:
            return "CLLocationManager.isRangingAvailable(): false"
        case .beaconMonitoringUnavailable:
            return "CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self): false"
        case .significantLocationChangeUnavailable:
            return "CLLocationManager.significantLocationChangeMonitoringAvailable(): false"
        case let .timeout(operation, duration):
            return "timeout_operation=\(operation),duration=\(duration)"
        case let .rangingFailed(region, underlyingError):
            return "ranging_region=\(region),underlying_error=\(underlyingError?.localizedDescription ?? "none")"
        case let .monitoringFailed(region, underlyingError):
            return "monitoring_region=\(region),underlying_error=\(underlyingError?.localizedDescription ?? "none")"
        case let .locationUpdateFailed(underlyingError):
            return "location_update_error=\(underlyingError?.localizedDescription ?? "unknown")"
        case let .significantLocationChangeFailed(underlyingError):
            return "slc_error=\(underlyingError?.localizedDescription ?? "unknown")"
        case .batteryOptimizationActive:
            return "battery_optimization_detected"
        case .memoryPressure:
            return "system_memory_pressure"
        case .networkUnavailable:
            return "network_connection_required"
        case .storageUnavailable:
            return "local_storage_unavailable"
        case let .invalidConfiguration(reason):
            return "invalid_config=\(reason)"
        case .unsupportedDevice:
            return "device_not_supported"
        case .regionLimitExceeded:
            return "region_limit_exceeded_ios_max_20"
        case let .systemError(underlyingError):
            return "system_error=\(underlyingError)"
        case let .unknown(code, description):
            return "unknown_error_code=\(code),description=\(description)"
        }
    }
}

// MARK: - NSError Bridging

extension LocationError: CustomNSError {
    
    public static var errorDomain: String {
        return LocationError.domain
    }
    
    public var errorCode: Int {
        return code
    }
    
    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription,
            NSLocalizedFailureReasonErrorKey: debugDescription
        ]
        
        // Add context-specific information
        switch self {
        case let .timeout(operation, duration):
            userInfo["operation"] = operation
            userInfo["duration"] = duration
        case let .rangingFailed(region, underlyingError):
            userInfo["region"] = region
            if let error = underlyingError {
                userInfo[NSUnderlyingErrorKey] = error
            }
        case let .monitoringFailed(region, underlyingError):
            userInfo["region"] = region
            if let error = underlyingError {
                userInfo[NSUnderlyingErrorKey] = error
            }
        case let .locationUpdateFailed(underlyingError):
            if let error = underlyingError {
                userInfo[NSUnderlyingErrorKey] = error
            }
        case let .significantLocationChangeFailed(underlyingError):
            if let error = underlyingError {
                userInfo[NSUnderlyingErrorKey] = error
            }
        case let .invalidConfiguration(reason):
            userInfo["reason"] = reason
        case let .systemError(underlyingError):
            userInfo[NSUnderlyingErrorKey] = underlyingError
        case let .unknown(code, description):
            userInfo["original_code"] = code
            userInfo["original_description"] = description
        default:
            break
        }
        
        return userInfo
    }
}