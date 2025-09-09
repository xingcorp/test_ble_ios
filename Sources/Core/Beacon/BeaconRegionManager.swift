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
public final class BeaconRegionManager: NSObject {
    private let manager = CLLocationManager()
    private var regions: [String: CLBeaconRegion] = [:] // key = siteId
    public weak var delegate: BeaconRegionManagerDelegate?
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    public func requestAlwaysAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .authorizedAlways: break
        case .notDetermined: manager.requestAlwaysAuthorization()
        default: manager.requestAlwaysAuthorization()
        }
    }
    
    public func configure(with sites: [SiteRegion]) {
        // Stop old
        for r in manager.monitoredRegions { 
            manager.stopMonitoring(for: r) 
        }
        regions.removeAll()
        
        // Start new
        for s in sites {
            let region: CLBeaconRegion
            if let major = s.major {
                region = CLBeaconRegion(uuid: s.uuid, major: major, identifier: s.siteId)
            } else {
                region = CLBeaconRegion(uuid: s.uuid, identifier: s.siteId)
            }
            region.notifyOnEntry = true
            region.notifyOnExit = true
            region.notifyEntryStateOnDisplay = true
            manager.startMonitoring(for: region)
            regions[s.siteId] = region
            // Proactively ask current state (useful after cold start)
            manager.requestState(for: region)
        }
    }
    
}

}

extension BeaconRegionManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let r = region as? CLBeaconRegion else { return }
        delegate?.didEnter(siteId: r.identifier)
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let r = region as? CLBeaconRegion else { return }
        delegate?.didExit(siteId: r.identifier)
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let r = region as? CLBeaconRegion else { return }
        delegate?.didDetermine(siteId: r.identifier, inside: state == .inside)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Optional: notify app about changes
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CLLocation error: \(error)")
    }
}

