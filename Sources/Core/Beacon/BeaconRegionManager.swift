//
//  BeaconRegionManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//  Copyright © 2024. All rights reserved.
//

import Foundation
import CoreLocation

public protocol BeaconRegionManagerDelegate: AnyObject {
    func didEnter(siteId: String)
    func didExit(siteId: String)
    func didDetermine(siteId: String, inside: Bool)
}

public struct SiteRegion: Hashable {
    public let siteId: String
    public let uuid: UUID
    public let major: CLBeaconMajorValue?
    
    public init(siteId: String, uuid: UUID, major: CLBeaconMajorValue? = nil) {
        self.siteId = siteId
        self.uuid = uuid
        self.major = major
    }
    
    public static let defaultUUID = UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")!
}

/// Monitors iBeacon regions (UUID or UUID+major). Handles app relaunch on region events.
/// Now uses UnifiedLocationService for consolidated location management
public final class BeaconRegionManager: NSObject {
    
    // MARK: - Dependencies
    
    /// UnifiedLocationService for all location operations
    private let unifiedLocationService: UnifiedLocationProvider
    
    /// Legacy regions tracking (key = siteId)
    public private(set) var regions: [String: CLBeaconRegion] = [:]
    
    /// Delegate for beacon region events
    public weak var delegate: BeaconRegionManagerDelegate?
    
    // MARK: - Backward Compatibility
    
    /// Deprecated direct access to CLLocationManager for backward compatibility
    /// AttendanceCoordinator currently uses this for delegate access
    @available(*, deprecated, message: "Direct CLLocationManager access is deprecated. Use BeaconRegionManager delegate pattern instead.")
    public var manager: CLLocationManager {
        LoggerService.shared.warning("⚠️ DEPRECATED: BeaconRegionManager.manager access. Migrate to delegate pattern.", category: .beacon)
        
        // Cast to UnifiedLocationService to access deprecated coreLocationManager property
        if let unifiedService = unifiedLocationService as? UnifiedLocationService {
            return unifiedService.coreLocationManager
        } else {
            // Fallback - this should never happen in practice
            fatalError("BeaconRegionManager requires UnifiedLocationService for backward compatibility")
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with UnifiedLocationService (recommended)
    /// - Parameter unifiedLocationService: The unified location service to use
    public init(unifiedLocationService: UnifiedLocationProvider = UnifiedLocationService.shared) {
        self.unifiedLocationService = unifiedLocationService
        super.init()
        
        // Register as beacon delegate
        if let unifiedService = unifiedLocationService as? UnifiedLocationService {
            unifiedService.addBeaconDelegate(self)
        }
        
        LoggerService.shared.info("✅ BeaconRegionManager initialized with UnifiedLocationService", category: .beacon)
    }
    
    // MARK: - Permission Management
    
    /// Request always authorization if needed
    public func requestAlwaysAuthorizationIfNeeded() {
        switch unifiedLocationService.authorizationStatus {
        case .authorizedAlways: 
            LoggerService.shared.info("✅ Already have Always authorization", category: .beacon)
        case .notDetermined: 
            LoggerService.shared.info("📍 Requesting Always authorization (not determined)", category: .beacon)
            unifiedLocationService.requestAlwaysAuthorization()
        default: 
            LoggerService.shared.info("📍 Requesting Always authorization (upgrading from current status)", category: .beacon)
            unifiedLocationService.requestAlwaysAuthorization()
        }
    }
    
    /// Current authorization status
    public var authorizationStatus: CLAuthorizationStatus {
        return unifiedLocationService.authorizationStatus
    }
    
    // MARK: - Region Configuration
    
    /// Configure monitoring for multiple sites
    /// - Parameter sites: Array of SiteRegion objects to monitor
    public func configure(with sites: [SiteRegion]) {
        LoggerService.shared.info("🔧 Configuring BeaconRegionManager with \(sites.count) sites", category: .beacon)
        
        // Stop monitoring old regions
        for existingRegion in unifiedLocationService.monitoredRegions {
            if let beaconRegion = existingRegion as? CLBeaconRegion {
                unifiedLocationService.stopMonitoring(for: beaconRegion)
                LoggerService.shared.debug("🛑 Stopped monitoring old region: \(beaconRegion.identifier)", category: .beacon)
            }
        }
        regions.removeAll()
        
        // Start monitoring new regions
        for site in sites {
            let region: CLBeaconRegion
            if let major = site.major {
                region = CLBeaconRegion(uuid: site.uuid, major: major, identifier: site.siteId)
                LoggerService.shared.debug("📡 Creating region: UUID=\(site.uuid.uuidString), Major=\(major), ID=\(site.siteId)", category: .beacon)
            } else {
                region = CLBeaconRegion(uuid: site.uuid, identifier: site.siteId)
                LoggerService.shared.debug("📡 Creating region: UUID=\(site.uuid.uuidString), ID=\(site.siteId)", category: .beacon)
            }
            
            // Configure region notifications
            region.notifyOnEntry = true
            region.notifyOnExit = true
            region.notifyEntryStateOnDisplay = true
            
            // Start monitoring via UnifiedLocationService
            unifiedLocationService.startMonitoring(for: region)
            regions[site.siteId] = region
            
            // Request initial state (important for cold start)
            unifiedLocationService.requestState(for: region)
            
            LoggerService.shared.info("✅ Started monitoring site: \(site.siteId)", category: .beacon)
        }
        
        LoggerService.shared.info("🎯 BeaconRegionManager configuration complete - monitoring \(regions.count) regions", category: .beacon)
    }
}

// MARK: - UnifiedBeaconDelegate

extension BeaconRegionManager: UnifiedBeaconDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didEnterRegion region: CLBeaconRegion) {
        LoggerService.shared.info("➡️ ENTERED beacon region: \(region.identifier)", category: .beacon)
        delegate?.didEnter(siteId: region.identifier)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didExitRegion region: CLBeaconRegion) {
        LoggerService.shared.info("⬅️ EXITED beacon region: \(region.identifier)", category: .beacon)
        delegate?.didExit(siteId: region.identifier)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        let stateString = state == .inside ? "INSIDE" : state == .outside ? "OUTSIDE" : "UNKNOWN"
        LoggerService.shared.info("🎯 DETERMINED state for \(region.identifier): \(stateString)", category: .beacon)
        delegate?.didDetermine(siteId: region.identifier, inside: state == .inside)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // BeaconRegionManager doesn't typically handle ranging directly
        // This is handled by other components like ShortRanger
        if !beacons.isEmpty {
            LoggerService.shared.debug("📡 Ranged \(beacons.count) beacon(s) in region: \(region.identifier)", category: .beacon)
        }
    }
}

// MARK: - Legacy CLLocationManagerDelegate Support

extension BeaconRegionManager: CLLocationManagerDelegate {
    
    /// Legacy delegate method - kept for backward compatibility
    /// Delegates to UnifiedLocationService implementation
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        LoggerService.shared.warning("⚠️ LEGACY: CLLocationManagerDelegate.didEnterRegion called. Should use UnifiedBeaconDelegate.", category: .beacon)
        unifiedLocationService(UnifiedLocationService.shared, didEnterRegion: beaconRegion)
    }
    
    /// Legacy delegate method - kept for backward compatibility
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        LoggerService.shared.warning("⚠️ LEGACY: CLLocationManagerDelegate.didExitRegion called. Should use UnifiedBeaconDelegate.", category: .beacon)
        unifiedLocationService(UnifiedLocationService.shared, didExitRegion: beaconRegion)
    }
    
    /// Legacy delegate method - kept for backward compatibility
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        LoggerService.shared.warning("⚠️ LEGACY: CLLocationManagerDelegate.didDetermineState called. Should use UnifiedBeaconDelegate.", category: .beacon)
        unifiedLocationService(UnifiedLocationService.shared, didDetermineState: state, for: beaconRegion)
    }
    
    /// Legacy delegate method - authorization changes are handled by UnifiedLocationService
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        LoggerService.shared.info("🔐 Authorization changed: \(status.rawValue) (handled by UnifiedLocationService)", category: .beacon)
        // Authorization is now handled centrally by UnifiedLocationService
    }
    
    /// Legacy delegate method - errors are handled by UnifiedLocationService
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LoggerService.shared.error("❌ LEGACY: CLLocationManager error (should be handled by UnifiedLocationService)", error: error, category: .beacon)
        // Errors are now handled centrally by UnifiedLocationService
    }
}

