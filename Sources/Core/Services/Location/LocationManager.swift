//
//  LocationManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Concrete implementation of LocationManagerProtocol
public final class LocationManager: NSObject, LocationManagerProtocol {
    
    // MARK: - Singleton
    public static let shared = LocationManager()
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Initialization
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    // MARK: - LocationManagerProtocol
    
    public func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            LoggerService.shared.warning("Location permission denied or restricted", category: .location)
        case .authorizedWhenInUse:
            // Request always authorization for beacon monitoring
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            LoggerService.shared.info("Location permission already granted", category: .location)
        @unknown default:
            LoggerService.shared.warning("Unknown location authorization status", category: .location)
        }
    }
    
    public func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    public func startLocationUpdates() {
        guard isLocationServicesEnabled() else {
            LoggerService.shared.warning("Location services not enabled", category: .location)
            return
        }
        
        locationManager.startUpdatingLocation()
        LoggerService.shared.info("Started location updates", category: .location)
    }
    
    public func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        LoggerService.shared.info("Stopped location updates", category: .location)
    }
    
    public func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public func getAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        LoggerService.shared.debug("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .location)
        
        // If we have a continuation waiting, fulfill it
        if let continuation = locationContinuation {
            self.locationContinuation = nil
            continuation.resume(returning: location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LoggerService.shared.error("Location manager failed", error: error, category: .location)
        
        // If we have a continuation waiting, fail it
        if let continuation = locationContinuation {
            self.locationContinuation = nil
            continuation.resume(throwing: error)
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
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
