//
//  BeaconManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Concrete implementation of BeaconManagerProtocol
public final class BeaconManager: NSObject, BeaconManagerProtocol {
    
    // MARK: - Properties
    
    public weak var delegate: BeaconManagerDelegate?
    private let locationManager: CLLocationManager
    private var monitoredRegions: [String: BeaconRegion] = [:]
    private var rangedRegions: [String: BeaconRegion] = [:]
    
    // MARK: - Initialization
    
    public override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // CRITICAL: Enable background mode for beacon monitoring
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.showsBackgroundLocationIndicator = false
        
        // Request always authorization for background monitoring
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    // MARK: - BeaconManagerProtocol
    
    public func startMonitoring(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        monitoredRegions[region.identifier] = region
        locationManager.startMonitoring(for: clRegion)
        
        LoggerService.shared.info("Started monitoring for beacon: \(region.identifier)", category: .beacon)
        
        // Force request state immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.locationManager.requestState(for: clRegion)
            LoggerService.shared.info("📍 Requested state for region: \(region.identifier)", category: .beacon)
        }
        
        // Log if no state determined after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if self.monitoredRegions[region.identifier] != nil {
                LoggerService.shared.warning("⚠️ No state determined after 5 seconds for region: \(region.identifier)", category: .beacon)
                LoggerService.shared.warning("🔍 This usually means beacon is not detected or UUID mismatch", category: .beacon)
                
                // Check if ranging is receiving any beacons
                if self.rangedRegions.isEmpty {
                    LoggerService.shared.warning("❌ No regions being ranged", category: .beacon)
                } else {
                    LoggerService.shared.info("✅ Ranging active for \(self.rangedRegions.count) region(s)", category: .beacon)
                }
            }
        }
        
        // Also try ranging immediately if monitoring is available
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            LoggerService.shared.info("✅ Monitoring available for beacons", category: .beacon)
        } else {
            LoggerService.shared.error("❌ Monitoring NOT available for beacons!", category: .beacon)
        }
    }
    
    public func stopMonitoring(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        monitoredRegions.removeValue(forKey: region.identifier)
        locationManager.stopMonitoring(for: clRegion)
        
        LoggerService.shared.info("Stopped monitoring for beacon: \(region.identifier)", category: .beacon)
    }
    
    public func startRanging(for region: BeaconRegion) {
        guard CLLocationManager.isRangingAvailable() else {
            LoggerService.shared.warning("Ranging not available on this device", category: .beacon)
            return
        }
        
        let clRegion = region.toCLBeaconRegion()
        rangedRegions[region.identifier] = region
        
        if #available(iOS 13.0, *) {
            locationManager.startRangingBeacons(satisfying: clRegion.beaconIdentityConstraint)
        } else {
            locationManager.startRangingBeacons(in: clRegion)
        }
        
        LoggerService.shared.info("Started ranging for beacon: \(region.identifier)", category: .beacon)
    }
    
    public func stopRanging(for region: BeaconRegion) {
        let clRegion = region.toCLBeaconRegion()
        rangedRegions.removeValue(forKey: region.identifier)
        
        if #available(iOS 13.0, *) {
            locationManager.stopRangingBeacons(satisfying: clRegion.beaconIdentityConstraint)
        } else {
            locationManager.stopRangingBeacons(in: clRegion)
        }
        
        LoggerService.shared.info("Stopped ranging for beacon: \(region.identifier)", category: .beacon)
    }
    
    public func isMonitoringAvailable() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
    }
    
    public func getMonitoredRegions() -> [BeaconRegion] {
        return Array(monitoredRegions.values)
    }
}

// MARK: - CLLocationManagerDelegate

extension BeaconManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion,
              let customRegion = monitoredRegions[beaconRegion.identifier] else { return }
        
        LoggerService.shared.info("Entered beacon region: \(beaconRegion.identifier)", category: .beacon)
        delegate?.beaconManager(self, didEnterRegion: customRegion)
        
        // Start ranging when entering region
        startRanging(for: customRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion,
              let customRegion = monitoredRegions[beaconRegion.identifier] else { return }
        
        LoggerService.shared.info("Exited beacon region: \(beaconRegion.identifier)", category: .beacon)
        delegate?.beaconManager(self, didExitRegion: customRegion)
        
        // Stop ranging when exiting region
        stopRanging(for: customRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let customRegion = rangedRegions[region.identifier] else { 
            LoggerService.shared.warning("⚠️ Ranged beacons for unknown region: \(region.identifier)", category: .beacon)
            return 
        }
        
        if !beacons.isEmpty {
            LoggerService.shared.info("✅ FOUND \(beacons.count) BEACON(S)!", category: .beacon)
            for beacon in beacons {
                LoggerService.shared.info("📡 Beacon: Major=\(beacon.major), Minor=\(beacon.minor), RSSI=\(beacon.rssi), Distance=\(beacon.accuracy)m", category: .beacon)
            }
        } else {
            // Log every 5 seconds that no beacons found
            LoggerService.shared.debug("🔍 No beacons in range for region: \(region.identifier)", category: .beacon)
        }
        
        delegate?.beaconManager(self, didRangeBeacons: beacons, in: customRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LoggerService.shared.error("Location manager failed", error: error, category: .beacon)
        delegate?.beaconManager(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        LoggerService.shared.error("Monitoring failed for region: \(region?.identifier ?? "unknown")", error: error, category: .beacon)
        delegate?.beaconManager(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        
        let stateString: String
        switch state {
        case .inside:
            stateString = "inside"
            LoggerService.shared.info("🟢 BEACON REGION INSIDE: \(beaconRegion.identifier)", category: .beacon)
            if let customRegion = monitoredRegions[beaconRegion.identifier] {
                delegate?.beaconManager(self, didEnterRegion: customRegion)
                startRanging(for: customRegion)
            }
        case .outside:
            stateString = "outside"
            LoggerService.shared.info("🔴 BEACON REGION OUTSIDE: \(beaconRegion.identifier)", category: .beacon)
            if let customRegion = monitoredRegions[beaconRegion.identifier] {
                delegate?.beaconManager(self, didExitRegion: customRegion)
                stopRanging(for: customRegion)
            }
        case .unknown:
            stateString = "unknown"
            LoggerService.shared.warning("⚠️ BEACON REGION UNKNOWN: \(beaconRegion.identifier)", category: .beacon)
        }
        
        LoggerService.shared.info("📍 Region state for \(beaconRegion.identifier): \(stateString) - UUID: \(beaconRegion.uuid)", category: .beacon)
    }
}
