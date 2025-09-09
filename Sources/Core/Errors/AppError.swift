//
//  AppError.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

/// Centralized error types for the entire app
public enum AppError: LocalizedError {
    
    // Permission errors
    case locationPermissionDenied
    case notificationPermissionDenied
    case bluetoothDisabled
    case backgroundRefreshDisabled
    
    // Beacon errors
    case regionMonitoringUnavailable
    case rangingUnavailable
    case beaconNotDetected
    case weakSignal(rssi: Int)
    
    // Session errors
    case noActiveSession
    case sessionAlreadyExists
    case invalidSessionData
    
    // Network errors
    case networkUnavailable
    case apiError(statusCode: Int, message: String?)
    case timeout
    case invalidResponse
    
    // Configuration errors
    case invalidConfiguration
    case missingConfiguration
    
    // Storage errors
    case storageError(underlying: Error)
    case dataCorrupted
    
    // Generic
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .locationPermissionDenied:
            return "Location permission is required. Please enable in Settings."
        case .notificationPermissionDenied:
            return "Notification permission is required for attendance alerts."
        case .bluetoothDisabled:
            return "Bluetooth is required for beacon detection."
        case .backgroundRefreshDisabled:
            return "Background App Refresh is required for reliable attendance tracking."
            
        case .regionMonitoringUnavailable:
            return "Region monitoring is not available on this device."
        case .rangingUnavailable:
            return "Beacon ranging is not available."
        case .beaconNotDetected:
            return "No beacons detected in range."
        case .weakSignal(let rssi):
            return "Weak beacon signal detected (RSSI: \(rssi))"
            
        case .noActiveSession:
            return "No active attendance session."
        case .sessionAlreadyExists:
            return "An attendance session is already active."
        case .invalidSessionData:
            return "Invalid session data."
            
        case .networkUnavailable:
            return "Network connection is unavailable."
        case .apiError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .timeout:
            return "Request timed out."
        case .invalidResponse:
            return "Invalid server response."
            
        case .invalidConfiguration:
            return "Invalid app configuration."
        case .missingConfiguration:
            return "App configuration is missing."
            
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .dataCorrupted:
            return "Data is corrupted."
            
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .locationPermissionDenied:
            return "Go to Settings > Privacy > Location Services and enable for this app."
        case .notificationPermissionDenied:
            return "Go to Settings > Notifications and enable for this app."
        case .bluetoothDisabled:
            return "Go to Settings > Bluetooth and turn it on."
        case .backgroundRefreshDisabled:
            return "Go to Settings > General > Background App Refresh and enable for this app."
        default:
            return nil
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .apiError(let code, _) where code >= 500:
            return true
        default:
            return false
        }
    }
}
