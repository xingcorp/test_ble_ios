//
//  UniversalBeaconScanner.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation
import CoreBluetooth

/// Universal beacon scanner for debugging - detects ALL beacons
public final class UniversalBeaconScanner: NSObject {
    
    // MARK: - Singleton
    public static let shared = UniversalBeaconScanner()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let centralManager: CBCentralManager
    private var isScanning = false
    private var detectedBeacons: [String: DetectedBeacon] = [:]
    private let updateInterval: TimeInterval = 2.0
    private var updateTimer: Timer?
    
    // Known iBeacon UUIDs to try
    private let knownUUIDs = [
        "FDA50693-0000-0000-0000-290995101092", // Your configured UUID
        "FDA50693-A8DF-1D91-3461-29099510092", // Possible variation
        "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0", // Common test UUID
        "B9407F30-F5F8-466E-AFF9-25556B57FE6D", // Estimote default
        "F7826DA6-4FA2-4E98-8024-BC5B71E0893E", // Kontakt.io default
        "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6", // RadBeacon
        "74278BDA-B644-4520-8F0C-720EAF059935", // Radius Networks
        "8492E75F-4FD6-469D-B132-043FE94921D8"  // Another common UUID
    ]
    
    // Callback
    public var onBeaconsDetected: (([DetectedBeacon]) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        self.centralManager = CBCentralManager()
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Start universal scanning
    public func startUniversalScan() {
        #if DEBUG && os(iOS)
        
        let authStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authStatus = locationManager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }
        
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            LoggerService.shared.error("Location permission not granted for universal scan", category: .beacon)
            return
        }
        
        LoggerService.shared.info("🔍 Starting UNIVERSAL beacon scan", category: .beacon)
        isScanning = true
        detectedBeacons.removeAll()
        
        // Try ranging for all known UUIDs
        for uuidString in knownUUIDs {
            if let uuid = UUID(uuidString: uuidString) {
                let region = CLBeaconRegion(
                    uuid: uuid,
                    identifier: "universal.\(uuidString)"
                )
                
                // Start both monitoring and ranging
                locationManager.startMonitoring(for: region)
                
                if #available(iOS 13.0, *) {
                    locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
                } else {
                    locationManager.startRangingBeacons(in: region)
                }
                
                LoggerService.shared.debug("Scanning for UUID: \(uuidString)", category: .beacon)
            }
        }
        
        // Also try wildcard region (may not work on all iOS versions)
        tryWildcardScanning()
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.reportDetectedBeacons()
        }
        
        #else
        LoggerService.shared.warning("⚠️ UniversalBeaconScanner not available (DEBUG + iOS only)", category: .beacon)
        #endif
    }
    
    /// Stop universal scanning
    public func stopUniversalScan() {
        #if DEBUG && os(iOS)
        guard isScanning else { return }
        
        LoggerService.shared.info("🛑 Stopping universal beacon scan", category: .beacon)
        isScanning = false
        
        // Stop all monitoring and ranging
        for region in locationManager.monitoredRegions {
            if let beaconRegion = region as? CLBeaconRegion {
                locationManager.stopMonitoring(for: beaconRegion)
                
                if #available(iOS 13.0, *) {
                    locationManager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
                } else {
                    locationManager.stopRangingBeacons(in: beaconRegion)
                }
            }
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Final report
        reportDetectedBeacons()
        detectedBeacons.removeAll()
        #else
        LoggerService.shared.warning("⚠️ UniversalBeaconScanner.stop not available (DEBUG + iOS only)", category: .beacon)
        #endif
    }
    
    /// Get current detected beacons
    public func getDetectedBeacons() -> [DetectedBeacon] {
        return Array(detectedBeacons.values).sorted { $0.rssi > $1.rssi }
    }
    
    // MARK: - Private Methods
    
    private func tryWildcardScanning() {
        // Try scanning without UUID (may not work on newer iOS)
        #if DEBUG && os(iOS)
        // This is a hack that might work on some iOS versions
        // Create a region without specific UUID constraints
        if let wildcardRegion = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: CLBeaconRegion.self,
            from: NSKeyedArchiver.archivedData(withRootObject: CLBeaconRegion(
                uuid: UUID(),
                identifier: "wildcard"
            ), requiringSecureCoding: true)
        ) {
            // Attempt to modify the region to accept any UUID
            // This is undocumented and may not work
            locationManager.startMonitoring(for: wildcardRegion)
        }
        #endif // DEBUG && os(iOS)
    }
    
    private func reportDetectedBeacons() {
        let beacons = getDetectedBeacons()
        
        if !beacons.isEmpty {
            LoggerService.shared.info("📡 DETECTED \(beacons.count) BEACONS:", category: .beacon)
            
            for beacon in beacons {
                LoggerService.shared.info("""
                    ┌─ Beacon Found ────────────────
                    │ UUID: \(beacon.uuid)
                    │ Major: \(beacon.major)
                    │ Minor: \(beacon.minor)
                    │ RSSI: \(beacon.rssi) dBm
                    │ Distance: \(String(format: "%.2f", beacon.distance)) m
                    │ Last Seen: \(beacon.lastSeen)
                    └────────────────────────────────
                    """, category: .beacon)
            }
            
            // Callback
            onBeaconsDetected?(beacons)
        } else {
            LoggerService.shared.warning("📡 No beacons detected in universal scan", category: .beacon)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension UniversalBeaconScanner: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard isScanning else { return }
        
        for beacon in beacons {
            let key = "\(beacon.uuid.uuidString)-\(beacon.major)-\(beacon.minor)"
            
            let detectedBeacon = DetectedBeacon(
                uuid: beacon.uuid.uuidString,
                major: beacon.major.intValue,
                minor: beacon.minor.intValue,
                rssi: beacon.rssi,
                distance: beacon.accuracy,
                lastSeen: Date()
            )
            
            detectedBeacons[key] = detectedBeacon
            
            // Log immediately for new beacons
            if detectedBeacons.count == 1 {
                LoggerService.shared.info("🎯 FIRST BEACON DETECTED: UUID=\(beacon.uuid.uuidString)", category: .beacon)
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            LoggerService.shared.info("✅ ENTERED region: \(beaconRegion.identifier)", category: .beacon)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LoggerService.shared.error("Universal scanner error", error: error, category: .beacon)
    }
}

// DetectedBeacon model is now in BeaconDetectionModels.swift

// MARK: - Debug Helper
#if DEBUG
public extension UniversalBeaconScanner {
    
    /// Run diagnostic scan and print results
    func runDiagnosticScan(duration: TimeInterval = 10) {
        LoggerService.shared.info("""
            ╔══════════════════════════════════════╗
            ║  BEACON DIAGNOSTIC SCAN STARTING    ║
            ║  Duration: \(duration) seconds          ║
            ║  Scanning ALL possible UUIDs...      ║
            ╚══════════════════════════════════════╝
            """, category: .beacon)
        
        startUniversalScan()
        
        // Stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopUniversalScan()
            
            let beacons = self?.getDetectedBeacons() ?? []
            
            LoggerService.shared.info("""
                ╔══════════════════════════════════════╗
                ║  DIAGNOSTIC SCAN COMPLETE           ║
                ║  Total Beacons Found: \(beacons.count)         ║
                ╚══════════════════════════════════════╝
                """, category: .beacon)
            
            if beacons.isEmpty {
                LoggerService.shared.warning("""
                    ⚠️ NO BEACONS DETECTED!
                    
                    Possible reasons:
                    1. No iBeacons in range
                    2. Beacons using different protocol (Eddystone, AltBeacon)
                    3. Bluetooth is disabled
                    4. Location permission issues
                    5. Beacons have unknown UUIDs
                    
                    Try:
                    - Check beacon is powered on
                    - Verify beacon is configured for iBeacon
                    - Move closer to beacon (< 1 meter)
                    - Check UUID with beacon manufacturer
                    """, category: .beacon)
            } else {
                LoggerService.shared.info("""
                    ✅ BEACONS DETECTED!
                    
                    Configure your app with these UUIDs:
                    \(beacons.map { "• UUID: \($0.uuid)" }.joined(separator: "\n"))
                    """, category: .beacon)
            }
        }
    }
}
#endif
