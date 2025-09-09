//
//  Validator.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

/// Protocol for validation rules
public protocol ValidationRule {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

/// Validation result
public enum ValidationResult {
    case valid
    case invalid(String)
    
    public var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    public var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

/// Common validators
public enum Validator {
    
    // MARK: - UUID Validation
    public static func validateUUID(_ string: String) -> ValidationResult {
        guard UUID(uuidString: string) != nil else {
            return .invalid("Invalid UUID format")
        }
        return .valid
    }
    
    // MARK: - Beacon Major/Minor Validation
    public static func validateBeaconMajor(_ value: Int) -> ValidationResult {
        guard value >= 0 && value <= 65535 else {
            return .invalid("Major must be between 0 and 65535")
        }
        return .valid
    }
    
    public static func validateBeaconMinor(_ value: Int) -> ValidationResult {
        guard value >= 0 && value <= 65535 else {
            return .invalid("Minor must be between 0 and 65535")
        }
        return .valid
    }
    
    // MARK: - RSSI Validation
    public static func validateRSSI(_ value: Int) -> ValidationResult {
        guard value >= -100 && value <= 0 else {
            return .invalid("RSSI must be between -100 and 0")
        }
        return .valid
    }
    
    // MARK: - Session Validation
    public static func validateSessionId(_ id: String) -> ValidationResult {
        guard !id.isEmpty else {
            return .invalid("Session ID cannot be empty")
        }
        
        guard id.count >= 10 else {
            return .invalid("Session ID is too short")
        }
        
        return .valid
    }
    
    // MARK: - Site ID Validation
    public static func validateSiteId(_ id: String) -> ValidationResult {
        guard !id.isEmpty else {
            return .invalid("Site ID cannot be empty")
        }
        
        guard id.rangeOfCharacter(from: .alphanumerics.inverted.subtracting(.init(charactersIn: "-_"))) == nil else {
            return .invalid("Site ID contains invalid characters")
        }
        
        return .valid
    }
    
    // MARK: - User ID Validation
    public static func validateUserId(_ id: String) -> ValidationResult {
        guard !id.isEmpty else {
            return .invalid("User ID cannot be empty")
        }
        
        guard id.count >= 3 else {
            return .invalid("User ID must be at least 3 characters")
        }
        
        return .valid
    }
    
    // MARK: - Time Interval Validation
    public static func validateTimeInterval(_ interval: TimeInterval, min: TimeInterval = 0, max: TimeInterval = .infinity) -> ValidationResult {
        guard interval >= min else {
            return .invalid("Time interval must be at least \(min) seconds")
        }
        
        guard interval <= max else {
            return .invalid("Time interval must be at most \(max) seconds")
        }
        
        return .valid
    }
    
    // MARK: - Coordinate Validation
    public static func validateLatitude(_ lat: Double) -> ValidationResult {
        guard lat >= -90 && lat <= 90 else {
            return .invalid("Latitude must be between -90 and 90")
        }
        return .valid
    }
    
    public static func validateLongitude(_ lon: Double) -> ValidationResult {
        guard lon >= -180 && lon <= 180 else {
            return .invalid("Longitude must be between -180 and 180")
        }
        return .valid
    }
    
    // MARK: - Battery Level Validation
    public static func validateBatteryLevel(_ level: Float) -> ValidationResult {
        guard level >= 0 && level <= 1 else {
            return .invalid("Battery level must be between 0 and 1")
        }
        return .valid
    }
}

// MARK: - Composite Validator

public struct CompositeValidator<T> {
    private let validators: [(T) -> ValidationResult]
    
    public init(validators: [(T) -> ValidationResult]) {
        self.validators = validators
    }
    
    public func validate(_ value: T) -> [ValidationResult] {
        return validators.map { $0(value) }
    }
    
    public func isValid(_ value: T) -> Bool {
        return validate(value).allSatisfy { $0.isValid }
    }
    
    public func errors(_ value: T) -> [String] {
        return validate(value).compactMap { $0.errorMessage }
    }
}
