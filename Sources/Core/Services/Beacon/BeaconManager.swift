//
//  BeaconManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Concrete implementation of BeaconManagerProtocol using UnifiedLocationService
public final class BeaconManager: NSObject, BeaconManagerProtocol {
    
    // MARK: - Properties
    
    public weak var delegate: BeaconManagerDelegate?
    private let unifiedService = UnifiedLocationService.shared
    private var monitoredRegions: [String: BeaconRegion] = [:]
    private var rangedRegions: [String: BeaconRegion] = [:]
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        
        // Register as delegate to UnifiedLocationService
        unifiedService.addBeaconDelegate(self)
        
        // Configure service for beacon monitoring
        unifiedService.desiredAccuracy = kCLLocationAccuracyBest
        unifiedService.allowsBackgroundLocationUpdates = true
        unifiedService.pausesLocationUpdatesAutomatically = false
        #if os(iOS)
        unifiedService.showsBackgroundLocationIndicator = false
        #endif
        
        // Check and request authorization if needed
        let status = unifiedService.authorizationStatus
        LoggerService.shared.info("🔐 Current location auth status: \(status.rawValue)", category: .beacon)
        
        if status != .authorizedAlways {
            unifiedService.requestLocationPermission()
        }
        
        LoggerService.shared.info("✅ BeaconManager initialized with UnifiedLocationService", category: .beacon)
    }
    
    // MARK: - BeaconManagerProtocol
    
    public func startMonitoring(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        monitoredRegions[region.identifier] = region
        
        // Delegate to UnifiedLocationService
        unifiedService.startMonitoring(for: clRegion)
        
        // Also start ranging immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startRanging(for: region)
        }
    }
    
    public func stopMonitoring(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        monitoredRegions.removeValue(forKey: region.identifier)
        
        // Delegate to UnifiedLocationService
        unifiedService.stopMonitoring(for: clRegion)
    }
    
    public func startRanging(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        rangedRegions[region.identifier] = region
        
        // Delegate to UnifiedLocationService
        unifiedService.startRangingBeacons(in: clRegion)
    }
    
    public func stopRanging(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        rangedRegions.removeValue(forKey: region.identifier)
        
        // Delegate to UnifiedLocationService
        unifiedService.stopRangingBeacons(in: clRegion)
    }
    
    public func isMonitoringAvailable() -> Bool {
        return UnifiedLocationService.isMonitoringAvailable(for: CLBeaconRegion.self)
    }
    
    public func getMonitoredRegions() -> [BeaconRegion] {
        return Array(monitoredRegions.values)
    }
}

// MARK: - UnifiedBeaconDelegate

extension BeaconManager: UnifiedBeaconDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didEnterRegion region: CLBeaconRegion) {
        guard let customRegion = monitoredRegions[region.identifier] else { return }
        
        LoggerService.shared.info("Entered beacon region: \(region.identifier)", category: .beacon)
        delegate?.beaconManager(self, didEnterRegion: customRegion)
        
        // Start ranging when entering region
        startRanging(for: customRegion)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didExitRegion region: CLBeaconRegion) {
        guard let customRegion = monitoredRegions[region.identifier] else { return }
        
        LoggerService.shared.info("Exited beacon region: \(region.identifier)", category: .beacon)
        delegate?.beaconManager(self, didExitRegion: customRegion)
        
        // Stop ranging when exiting region
        stopRanging(for: customRegion)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let customRegion = rangedRegions[region.identifier] else { 
            LoggerService.shared.warning("⚠️ Ranged beacons for unknown region: \(region.identifier)", category: .beacon)
            return 
        }
        
        if !beacons.isEmpty {
            for beacon in beacons.prefix(3) { // Log first 3 to avoid spam
                LoggerService.shared.debug("📡 Beacon: Major=\(beacon.major), Minor=\(beacon.minor), RSSI=\(beacon.rssi), Distance=\(beacon.accuracy)m", category: .beacon)
            }
        }
        
        delegate?.beaconManager(self, didRangeBeacons: beacons, in: customRegion)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        guard let customRegion = monitoredRegions[region.identifier] else { return }
        
        switch state {
        case .inside:
            LoggerService.shared.info("🟢 BEACON REGION INSIDE: \(region.identifier)", category: .beacon)
            delegate?.beaconManager(self, didEnterRegion: customRegion)
            startRanging(for: customRegion)
        case .outside:
            LoggerService.shared.info("🔴 BEACON REGION OUTSIDE: \(region.identifier)", category: .beacon)
            delegate?.beaconManager(self, didExitRegion: customRegion)
            stopRanging(for: customRegion)
        case .unknown:
            LoggerService.shared.warning("⚠️ BEACON REGION UNKNOWN: \(region.identifier)", category: .beacon)
        }
    }
}
