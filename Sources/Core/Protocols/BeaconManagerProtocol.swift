//
//  BeaconManagerProtocol.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Protocol for beacon detection and ranging
public protocol BeaconManagerProtocol: AnyObject {
    var delegate: BeaconManagerDelegate? { get set }
    
    /// Start monitoring for beacon regions
    func startMonitoring(for region: BeaconRegion)
    
    /// Stop monitoring for beacon regions
    func stopMonitoring(for region: BeaconRegion)
    
    /// Start ranging beacons in region
    func startRanging(for region: BeaconRegion)
    
    /// Stop ranging beacons in region
    func stopRanging(for region: BeaconRegion)
    
    /// Check if beacon monitoring is available
    func isMonitoringAvailable() -> Bool
    
    /// Get all monitored regions
    func getMonitoredRegions() -> [BeaconRegion]
}

/// Delegate for beacon manager events
public protocol BeaconManagerDelegate: AnyObject {
    /// Called when device enters beacon region
    func beaconManager(_ manager: BeaconManagerProtocol, didEnterRegion region: BeaconRegion)
    
    /// Called when device exits beacon region
    func beaconManager(_ manager: BeaconManagerProtocol, didExitRegion region: BeaconRegion)
    
    /// Called when beacons are ranged
    func beaconManager(_ manager: BeaconManagerProtocol, didRangeBeacons beacons: [CLBeacon], in region: BeaconRegion)
    
    /// Called when error occurs
    func beaconManager(_ manager: BeaconManagerProtocol, didFailWithError error: Error)
}
