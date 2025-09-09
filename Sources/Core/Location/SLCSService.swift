//
//  SLCSService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

public protocol SLCSServiceDelegate: AnyObject {
    func didTriggerSignificantChange()
}

public final class SLCSService: NSObject {
    private let manager = CLLocationManager()
    public weak var delegate: SLCSServiceDelegate?
    
    public override init() {
        super.init()
        manager.delegate = self
    }
    
    public func start() {
        manager.startMonitoringSignificantLocationChanges()
    }
    
    public func stop() {
        manager.stopMonitoringSignificantLocationChanges()
    }
}

extension SLCSService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.didTriggerSignificantChange()
    }
}
