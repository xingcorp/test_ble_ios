//
//  ShortRanger.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

public struct RangingSnapshot {
    public let beacons: [CLBeacon]
    public let nearest: CLBeacon?
}

public protocol ShortRangerDelegate: AnyObject {
    func didProduce(snapshot: RangingSnapshot)
    func didFinish(final: RangingSnapshot?)
}

/// Time‑boxed ranging session (5–10s). Use uuid(+major) constraints.
public final class ShortRanger: NSObject {
    private let manager = CLLocationManager()
    private var constraints: [CLBeaconIdentityConstraint] = []
    private var timer: Timer?
    public weak var delegate: ShortRangerDelegate?
    private let smoother = RSSISmoother(window: 5)
    
    public override init() {
        super.init()
        manager.delegate = self
    }
    
    public func start(constraints: [CLBeaconIdentityConstraint], duration: TimeInterval = 8.0) {
        stop()
        self.constraints = constraints
        for c in constraints { 
            manager.startRangingBeacons(satisfying: c) 
        }
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.finish()
        }
    }
    
    public func stop() {
        for c in constraints { 
            manager.stopRangingBeacons(satisfying: c) 
        }
        constraints.removeAll()
        timer?.invalidate()
        timer = nil
    }
    
    private func finish() {
        stop()
        delegate?.didFinish(final: nil)
    }
}

extension ShortRanger: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
        // Smooth RSSI and compute nearest
        let smoothed = beacons.sorted { smoother.value(for: $0) > smoother.value(for: $1) }
        let snapshot = RangingSnapshot(beacons: smoothed, nearest: smoothed.first)
        delegate?.didProduce(snapshot: snapshot)
    }
}

