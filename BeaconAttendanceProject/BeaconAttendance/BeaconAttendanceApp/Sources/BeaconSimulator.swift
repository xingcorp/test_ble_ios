//
//  BeaconSimulator.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation
import BeaconAttendanceCore

/// Simulator for testing beacon detection without physical beacons
final class BeaconSimulator {
    
    static let shared = BeaconSimulator()
    
    private var timer: Timer?
    private weak var delegate: BeaconManagerDelegate?
    
    private init() {}
    
    /// Start simulating beacon detection
    func startSimulating(delegate: BeaconManagerDelegate?) {
        self.delegate = delegate
        
        // Simulate entering region after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.simulateEnterRegion()
        }
        
        // Start ranging simulation
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.simulateRanging()
        }
        
        LoggerService.shared.info("🎮 Beacon simulator started", category: .beacon)
    }
    
    /// Stop simulating
    func stopSimulating() {
        timer?.invalidate()
        timer = nil
        
        // Simulate exit region
        simulateExitRegion()
        
        LoggerService.shared.info("🎮 Beacon simulator stopped", category: .beacon)
    }
    
    private func simulateEnterRegion() {
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.major-4470",
            uuid: UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")!,
            major: 4470,
            minor: nil
        )
        
        delegate?.beaconManager(BeaconManager(), didEnterRegion: region)
        LoggerService.shared.info("🎮 SIMULATED: Entered beacon region", category: .beacon)
    }
    
    private func simulateExitRegion() {
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.major-4470",
            uuid: UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")!,
            major: 4470,
            minor: nil
        )
        
        delegate?.beaconManager(BeaconManager(), didExitRegion: region)
        LoggerService.shared.info("🎮 SIMULATED: Exited beacon region", category: .beacon)
    }
    
    private func simulateRanging() {
        // Create fake beacon
        let beacon = FakeCLBeacon(
            uuid: UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")!,
            major: 4470,
            minor: UInt16.random(in: 1000...9999), // Random minor to simulate rolling
            proximity: .near,
            accuracy: Double.random(in: 1.0...5.0),
            rssi: Int.random(in: -80...-40)
        )
        
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.major-4470",
            uuid: beacon.uuid,
            major: beacon.major.uint16Value,
            minor: nil
        )
        
        delegate?.beaconManager(BeaconManager(), didRangeBeacons: [beacon], in: region)
    }
}

/// Fake CLBeacon for testing (since CLBeacon can't be instantiated)
class FakeCLBeacon: CLBeacon {
    private let _uuid: UUID
    private let _major: NSNumber
    private let _minor: NSNumber
    private let _proximity: CLProximity
    private let _accuracy: CLLocationAccuracy
    private let _rssi: Int
    
    init(uuid: UUID, major: UInt16, minor: UInt16, proximity: CLProximity, accuracy: CLLocationAccuracy, rssi: Int) {
        self._uuid = uuid
        self._major = NSNumber(value: major)
        self._minor = NSNumber(value: minor)
        self._proximity = proximity
        self._accuracy = accuracy
        self._rssi = rssi
        super.init()
    }
    
    override var uuid: UUID { _uuid }
    override var major: NSNumber { _major }
    override var minor: NSNumber { _minor }
    override var proximity: CLProximity { _proximity }
    override var accuracy: CLLocationAccuracy { _accuracy }
    override var rssi: Int { _rssi }
}

// MARK: - Debug Extension for AttendanceViewController

extension AttendanceViewController {
    
    /// Enable beacon simulation for testing
    func enableBeaconSimulation() {
        #if DEBUG
        let alert = UIAlertController(
            title: "Enable Beacon Simulation?",
            message: "This will simulate beacon detection for testing purposes.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Enable", style: .default) { [weak self] _ in
            BeaconSimulator.shared.startSimulating(delegate: self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                BeaconSimulator.shared.stopSimulating()
            }
        })
        
        present(alert, animated: true)
        #endif
    }
}
