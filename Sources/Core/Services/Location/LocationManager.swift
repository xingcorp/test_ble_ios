//
//  LocationManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Concrete implementation of LocationManagerProtocol using UnifiedLocationService
public final class LocationManager: NSObject, LocationManagerProtocol {
    
    // MARK: - Singleton
    public static let shared = LocationManager()
    
    // MARK: - Properties
    
    private let unifiedService = UnifiedLocationService.shared
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Register as delegate to UnifiedLocationService
        unifiedService.addLocationDelegate(self)
        
        // Configure service
        unifiedService.desiredAccuracy = kCLLocationAccuracyBest
        unifiedService.distanceFilter = 10 // Update every 10 meters
        
        LoggerService.shared.info("✅ LocationManager initialized with UnifiedLocationService", category: .location)
    }
    
    // MARK: - LocationManagerProtocol
    
    public func requestLocationPermission() {
        unifiedService.requestLocationPermission()
    }
    
    public func getCurrentLocation() async throws -> CLLocation {
        return try await unifiedService.getCurrentLocation()
    }
    
    public func startLocationUpdates() {
        guard isLocationServicesEnabled() else {
            LoggerService.shared.warning("Location services not enabled", category: .location)
            return
        }
        
        unifiedService.startUpdatingLocation()
    }
    
    public func stopLocationUpdates() {
        unifiedService.stopUpdatingLocation()
    }
    
    public func isLocationServicesEnabled() -> Bool {
        return UnifiedLocationService.locationServicesEnabled()
    }
    
    public func getAuthorizationStatus() -> CLAuthorizationStatus {
        return unifiedService.authorizationStatus
    }
}

// MARK: - UnifiedLocationDelegate

extension LocationManager: UnifiedLocationDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        LoggerService.shared.debug("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .location)
        
        // Notification for backwards compatibility
        NotificationCenter.default.post(
            name: Notification.Name("LocationDidUpdate"),
            object: nil,
            userInfo: ["location": location]
        )
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didFailWithError error: Error) {
        LoggerService.shared.error("Location service failed", error: error, category: .location)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didChangeAuthorization status: CLAuthorizationStatus) {
        let statusString: String
        switch status {
        case .notDetermined:
            statusString = "notDetermined"
        case .restricted:
            statusString = "restricted"
        case .denied:
            statusString = "denied"
        case .authorizedAlways:
            statusString = "authorizedAlways"
        case .authorizedWhenInUse:
            statusString = "authorizedWhenInUse"
        @unknown default:
            statusString = "unknown"
        }
        
        LoggerService.shared.info("Location authorization changed: \(statusString)", category: .location)
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: Notification.Name("LocationAuthorizationChanged"),
            object: nil,
            userInfo: ["status": status]
        )
    }
}
