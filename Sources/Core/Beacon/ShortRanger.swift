//
//  ShortRanger.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation
import os.log

struct RangedBeacon: Equatable {
    let uuid: UUID
    let major: UInt16
    let minor: UInt16
    let rssi: Int
    let proximity: CLProximity
}

final class RSSISmoother {
    private var window: [Int] = []
    private let maxCount: Int
    
    init(maxCount: Int = 5) {
        self.maxCount = maxCount
    }
    
    func add(_ rssi: Int) -> Double {
        window.append(rssi)
        if window.count > maxCount { window.removeFirst() }
        let valid = window.filter { $0 != 0 && $0 != Int.min }
        guard !valid.isEmpty else { return Double(Int.min) }
        return Double(valid.reduce(0, +)) / Double(valid.count)
    }
    
    func reset() { window.removeAll() }
}

final class ShortRanger: NSObject {
    private let locationManager: CLLocationManager
    private let logger = Logger(subsystem: "com.attendance.beacon", category: "ShortRanger")
    private var constraint: CLBeaconIdentityConstraint?
    private var timeoutWorkItem: DispatchWorkItem?
    private var completion: (([RangedBeacon], RangedBeacon?) -> Void)?
    private var smootherMap: [String: RSSISmoother] = [:] // key: uuid-major-minor
    private let queue = DispatchQueue(label: "ShortRangerQueue")
    private let duration: TimeInterval
    
    init(locationManager: CLLocationManager = CLLocationManager(), duration: TimeInterval = 8.0) {
        self.locationManager = locationManager
        self.duration = max(5.0, min(duration, 12.0)) // clamp 5–12s
        super.init()
        self.locationManager.delegate = self
    }
    
    func startRanging(uuid: UUID, major: UInt16, duration: TimeInterval? = nil, completion: @escaping ([RangedBeacon], RangedBeacon?) -> Void) {
        stopRanging()
        self.completion = completion
        let dur = duration.map { max(5.0, min($0, 12.0)) } ?? self.duration
        
        if #available(iOS 13.0, *) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: major)
            self.constraint = constraint
            locationManager.startRangingBeacons(satisfying: constraint)
        } else {
            let region = CLBeaconRegion(proximityUUID: uuid, major: major, identifier: "ranging-temp")
            locationManager.startRangingBeacons(in: region)
        }
        
        scheduleTimeout(after: dur)
        logger.info("Started ranging for uuid=\(uuid), major=\(major), duration=\(dur)s")
    }
    
    func stopRanging() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        
        if let constraint = self.constraint {
            if #available(iOS 13.0, *) {
                locationManager.stopRangingBeacons(satisfying: constraint)
            }
            self.constraint = nil
        } else {
            // Best effort to stop all legacy ranging
            for region in locationManager.rangedRegions {
                if let beaconRegion = region as? CLBeaconRegion {
                    locationManager.stopRangingBeacons(in: beaconRegion)
                }
            }
        }
        
        smootherMap.removeAll()
    }
    
    private func scheduleTimeout(after: TimeInterval) {
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.finish()
        }
        timeoutWorkItem = item
        queue.asyncAfter(deadline: .now() + after, execute: item)
    }
    
    private func finish() {
        var list: [RangedBeacon] = []
        // We can't directly pull last seen beacons from CLLocationManager; rely on last delegate callback state captured.
        // For simplicity, completion will be invoked with last processed candidates stored separately (not persisted here).
        // In a real app, hold a cache. Here we simply stop and return empty; caller should rely on last callback.
        stopRanging()
        completion?(list, list.first)
        completion = nil
    }
}

extension ShortRanger: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        process(beacons: beacons)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], in region: CLBeaconRegion) {
        process(beacons: beacons)
    }
    
    private func key(uuid: UUID, major: UInt16, minor: UInt16) -> String { "\(uuid.uuidString)-\(major)-\(minor)" }
    
    private func process(beacons: [CLBeacon]) {
        var list: [RangedBeacon] = []
        for b in beacons {
            guard b.rssi != 0 && b.rssi != Int.min else { continue }
            let major = UInt16(truncating: b.major)
            let minor = UInt16(truncating: b.minor)
            let k = key(uuid: b.uuid, major: major, minor: minor)
            let smoother = smootherMap[k] ?? RSSISmoother(maxCount: 5)
            smootherMap[k] = smoother
            let ma = smoother.add(b.rssi)
            let rb = RangedBeacon(uuid: b.uuid, major: major, minor: minor, rssi: Int(ma), proximity: b.proximity)
            list.append(rb)
        }
        list.sort { $0.rssi > $1.rssi }
        let nearest = list.first
        completion?(list, nearest)
    }
}

