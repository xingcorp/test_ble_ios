//
//  BeaconSimulator.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Protocol for simulating beacon behavior
public protocol BeaconSimulating {
    func startSimulating(beaconId: String, rssi: Int)
    func stopSimulating()
    func updateRSSI(_ rssi: Int)
    var isSimulating: Bool { get }
}

/// Beacon simulator for testing without physical beacons
public final class BeaconSimulator: BeaconSimulating {
    
    // MARK: - Singleton
    public static let shared = BeaconSimulator()
    
    // MARK: - Properties
    private var timer: Timer?
    private var currentBeacon: SimulatedBeacon?
    private var rssiVariation: Int = 5
    private let updateInterval: TimeInterval = 1.0
    
    public private(set) var isSimulating = false
    
    // Callbacks
    public var onBeaconDetected: ((SimulatedBeacon) -> Void)?
    public var onBeaconLost: (() -> Void)?
    public var onRSSIUpdate: ((Int) -> Void)?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start simulating a beacon
    public func startSimulating(beaconId: String, rssi: Int = -65) {
        guard !isSimulating else { 
            LoggerService.shared.warning("Beacon simulation already running", category: .beacon)
            return 
        }
        
        #if targetEnvironment(simulator)
        isSimulating = true
        
        // Create simulated beacon
        currentBeacon = SimulatedBeacon(
            uuid: UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")!,
            major: 100,
            minor: 1,
            rssi: rssi,
            accuracy: calculateAccuracy(from: rssi)
        )
        
        // Notify detection
        if let beacon = currentBeacon {
            onBeaconDetected?(beacon)
            LoggerService.shared.info("📡 Simulated beacon detected: \(beaconId), RSSI: \(rssi)", category: .beacon)
        }
        
        // Start RSSI fluctuation timer
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.simulateRSSIFluctuation()
        }
        
        // Send notification
        NotificationCenter.default.post(
            name: .beaconSimulatorStarted,
            object: currentBeacon
        )
        #else
        LoggerService.shared.warning("Beacon simulation only works on Simulator", category: .beacon)
        #endif
    }
    
    /// Stop beacon simulation
    public func stopSimulating() {
        guard isSimulating else { return }
        
        isSimulating = false
        timer?.invalidate()
        timer = nil
        currentBeacon = nil
        
        onBeaconLost?()
        
        LoggerService.shared.info("📡 Beacon simulation stopped", category: .beacon)
        
        // Send notification
        NotificationCenter.default.post(
            name: .beaconSimulatorStopped,
            object: nil
        )
    }
    
    /// Update RSSI value
    public func updateRSSI(_ rssi: Int) {
        guard isSimulating, currentBeacon != nil else { return }
        
        currentBeacon?.rssi = rssi
        currentBeacon?.accuracy = calculateAccuracy(from: rssi)
        
        onRSSIUpdate?(rssi)
        
        // Send notification
        NotificationCenter.default.post(
            name: .beaconSimulatorRSSIChanged,
            object: nil,
            userInfo: ["rssi": rssi]
        )
    }
    
    /// Simulate walking closer to beacon
    public func simulateApproach(duration: TimeInterval = 5.0) {
        guard isSimulating else { return }
        
        let steps = Int(duration)
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            currentStep += 1
            
            // Gradually increase RSSI (get closer)
            let newRSSI = -80 + (currentStep * 5)
            self.updateRSSI(min(-30, newRSSI))
            
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }
    
    /// Simulate walking away from beacon
    public func simulateExit(duration: TimeInterval = 5.0) {
        guard isSimulating else { return }
        
        let steps = Int(duration)
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            currentStep += 1
            
            // Gradually decrease RSSI (get farther)
            let newRSSI = -65 - (currentStep * 5)
            self.updateRSSI(max(-100, newRSSI))
            
            if currentStep >= steps {
                timer.invalidate()
                self.stopSimulating()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func simulateRSSIFluctuation() {
        guard let beacon = currentBeacon else { return }
        
        // Add random variation to RSSI
        let variation = Int.random(in: -rssiVariation...rssiVariation)
        let newRSSI = max(-100, min(-30, beacon.rssi + variation))
        
        updateRSSI(newRSSI)
    }
    
    private func calculateAccuracy(from rssi: Int) -> CLLocationAccuracy {
        // Simple path loss formula for distance estimation
        let txPower = -59.0 // Calibrated TX power at 1 meter
        let n = 2.0 // Path loss exponent
        
        let distance = pow(10, (txPower - Double(rssi)) / (10 * n))
        return distance
    }
}

// MARK: - Simulated Beacon Model
public class SimulatedBeacon {
    public let uuid: UUID
    public let major: CLBeaconMajorValue
    public let minor: CLBeaconMinorValue
    public var rssi: Int
    public var accuracy: CLLocationAccuracy
    
    init(uuid: UUID, major: CLBeaconMajorValue, minor: CLBeaconMinorValue, rssi: Int, accuracy: CLLocationAccuracy) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.rssi = rssi
        self.accuracy = accuracy
    }
    
    /// Convert to dictionary for easy integration
    public func toDictionary() -> [String: Any] {
        return [
            "uuid": uuid.uuidString,
            "major": major,
            "minor": minor,
            "rssi": rssi,
            "accuracy": accuracy
        ]
    }
}

// MARK: - Notification Names
public extension Notification.Name {
    static let beaconSimulatorStarted = Notification.Name("beaconSimulatorStarted")
    static let beaconSimulatorStopped = Notification.Name("beaconSimulatorStopped")
    static let beaconSimulatorRSSIChanged = Notification.Name("beaconSimulatorRSSIChanged")
}

// MARK: - Debug Commands
#if DEBUG
public extension BeaconSimulator {
    
    /// Test various scenarios
    enum TestScenario {
        case checkInOut
        case weakSignal
        case signalLoss
        case multipleBeacons
        case rapidMovement
    }
    
    func runTestScenario(_ scenario: TestScenario) {
        switch scenario {
        case .checkInOut:
            // Simulate normal check-in and check-out
            startSimulating(beaconId: "test-beacon", rssi: -65)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.simulateExit(duration: 5)
            }
            
        case .weakSignal:
            // Simulate weak signal condition
            startSimulating(beaconId: "test-beacon", rssi: -85)
            rssiVariation = 10 // More variation
            
        case .signalLoss:
            // Simulate sudden signal loss
            startSimulating(beaconId: "test-beacon", rssi: -65)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.stopSimulating()
            }
            
        case .multipleBeacons:
            // Simulate multiple beacons (would need enhancement)
            startSimulating(beaconId: "beacon-1", rssi: -65)
            LoggerService.shared.info("Multiple beacon simulation not yet implemented", category: .beacon)
            
        case .rapidMovement:
            // Simulate rapid movement
            startSimulating(beaconId: "test-beacon", rssi: -65)
            rssiVariation = 15 // High variation
            
            // Rapid changes
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                let randomRSSI = Int.random(in: -90...(-40))
                self.updateRSSI(randomRSSI)
            }
        }
        
        LoggerService.shared.info("Running test scenario: \(scenario)", category: .beacon)
    }
}
#endif
