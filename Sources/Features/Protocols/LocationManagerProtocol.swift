//
//  LocationManagerProtocol.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Protocol for location management
public protocol LocationManagerProtocol: AnyObject {
    /// Request location permissions
    func requestLocationPermission()
    
    /// Get current location
    func getCurrentLocation() async throws -> CLLocation
    
    /// Start location updates
    func startLocationUpdates()
    
    /// Stop location updates
    func stopLocationUpdates()
    
    /// Check if location services are enabled
    func isLocationServicesEnabled() -> Bool
    
    /// Get current authorization status
    func getAuthorizationStatus() -> CLAuthorizationStatus
}
