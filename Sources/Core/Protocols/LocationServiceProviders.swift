//
//  LocationServiceProviders.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Purpose: Protocol abstractions for location service components
//

import Foundation
import CoreLocation

// MARK: - Location Service Provider Protocols

/// Protocol for services requiring significant location change monitoring
/// Used by SLCSService to maintain single responsibility
public protocol SignificantLocationChangeProvider: AnyObject {
    /// Start monitoring significant location changes
    func startMonitoringSignificantLocationChanges()
    
    /// Stop monitoring significant location changes  
    func stopMonitoringSignificantLocationChanges()
    
    /// Check if significant location change monitoring is available
    static func significantLocationChangeMonitoringAvailable() -> Bool
}

/// Protocol for services requiring beacon ranging capabilities
/// Used by ShortRanger and debug scanner components
public protocol BeaconRangingProvider: AnyObject {
    /// Start ranging beacons in the specified region
    func startRangingBeacons(in region: CLBeaconRegion)
    
    /// Stop ranging beacons in the specified region
    func stopRangingBeacons(in region: CLBeaconRegion)
    
    /// Check if beacon ranging is available on this device
    static func isRangingAvailable() -> Bool
}

/// Protocol for services requiring beacon region monitoring
/// Used by BeaconRegionManager and attendance coordinators  
public protocol BeaconMonitoringProvider: AnyObject {
    /// Start monitoring the specified beacon region
    func startMonitoring(for region: CLBeaconRegion)
    
    /// Stop monitoring the specified beacon region
    func stopMonitoring(for region: CLBeaconRegion)
    
    /// Request the current state for a region
    func requestState(for region: CLRegion)
    
    /// Get currently monitored regions
    var monitoredRegions: Set<CLRegion> { get }
    
    /// Check if monitoring is available for the specified region class
    static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool
}

/// Protocol for services requiring basic location updates
/// Used by LocationManager and coordinate-based services
public protocol LocationUpdateProvider: AnyObject {
    /// Start updating location
    func startUpdatingLocation()
    
    /// Stop updating location  
    func stopUpdatingLocation()
    
    /// Request a single location update
    func requestLocation()
    
    /// Get current location asynchronously
    func getCurrentLocation() async throws -> CLLocation
    
    /// Check if location services are enabled
    static func locationServicesEnabled() -> Bool
}

/// Protocol for permission management
/// Ensures consistent permission handling across services
public protocol LocationPermissionProvider: AnyObject {
    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus { get }
    
    /// Request when-in-use authorization
    func requestWhenInUseAuthorization()
    
    /// Request always authorization  
    func requestAlwaysAuthorization()
    
    /// Request appropriate location permission based on current state
    func requestLocationPermission()
}

// MARK: - Composite Provider Protocol

/// Composite protocol combining all location service capabilities
/// UnifiedLocationService conforms to this to provide all functionality
public protocol UnifiedLocationProvider: LocationUpdateProvider, 
                                        BeaconMonitoringProvider,
                                        BeaconRangingProvider, 
                                        SignificantLocationChangeProvider,
                                        LocationPermissionProvider {
    // Inherits all methods from component protocols
}

// MARK: - Performance Monitoring

/// Protocol for tracking location service performance metrics
public protocol LocationServiceMetrics: AnyObject {
    /// Track operation performance
    func trackOperation(_ operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]?)
    
    /// Get current battery impact estimate
    var batteryImpactEstimate: Double { get }
    
    /// Get service usage statistics
    func getUsageStatistics() -> [String: Any]
}