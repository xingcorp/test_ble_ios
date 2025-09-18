//
//  UniversalBeaconScanner.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//  ARCHITECTURAL FIX: Integrated with UnifiedLocationService to prevent CLLocationManager conflicts
//

import Foundation
import CoreLocation
import CoreBluetooth

/// Universal beacon scanner for debugging - detects ALL beacons
/// ARCHITECTURAL FIX: Uses centralized UnifiedLocationService to prevent region conflicts
public final class UniversalBeaconScanner: NSObject {
    
    // MARK: - Singleton
    public static let shared = UniversalBeaconScanner()
    
    // MARK: - Properties
    private let unifiedLocationService = UnifiedLocationService.shared // FIX: Use centralized service
    private let centralManager: CBCentralManager
    private var isScanning = false
    private var detectedBeacons: [String: DetectedBeacon] = [:]
    private let updateInterval: TimeInterval = 2.0
    private var updateTimer: Timer?
    private var registeredRegions: [String] = [] // Track our registered regions
    
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
        // FIX: Register as delegate with centralized service
        unifiedLocationService.addBeaconDelegate(self)
        
        LoggerService.shared.info("✅ UniversalBeaconScanner initialized with centralized UnifiedLocationService", category: .beacon)
    }
    
    // MARK: - Public Methods
    
    /// Start universal scanning
    public func startUniversalScan() {
        #if DEBUG && os(iOS)
        
        // FIX: Use UnifiedLocationService for authorization status
        let authStatus = unifiedLocationService.authorizationStatus
        
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            LoggerService.shared.error("Location permission not granted for universal scan", category: .beacon)
            return
        }
        
        LoggerService.shared.info("🔍 Starting UNIVERSAL beacon scan via UnifiedLocationService", category: .beacon)
        isScanning = true
        detectedBeacons.removeAll()
        registeredRegions.removeAll()
        
        // Check current region usage to prevent conflicts
        let currentRegions = unifiedLocationService.monitoredRegions.count
        LoggerService.shared.info("📡 BEFORE universal scan - Currently monitoring: \(currentRegions) regions", category: .beacon)
        
        // Calculate how many regions we can safely add (leave buffer for app regions)
        let maxUniversalRegions = min(knownUUIDs.count, 20 - currentRegions - 2) // Leave 2 region buffer
        
        if maxUniversalRegions <= 0 {
            LoggerService.shared.error("🚨 Cannot start universal scan - region limit would be exceeded (current: \(currentRegions))", category: .beacon)
            return
        }
        
        LoggerService.shared.info("📡 Will register \(maxUniversalRegions) universal scan regions", category: .beacon)
        
        // Register regions with unique identifiers to prevent conflicts
        for (index, uuidString) in knownUUIDs.prefix(maxUniversalRegions).enumerated() {
            if let uuid = UUID(uuidString: uuidString) {
                // Use timestamp to ensure unique identifiers and prevent conflicts with app regions
                let uniqueIdentifier = "universal_debug_\(Date().timeIntervalSince1970)_\(index)"
                let region = CLBeaconRegion(
                    uuid: uuid,
                    identifier: uniqueIdentifier
                )
                
                LoggerService.shared.debug("📡 Creating universal region: ID='\(region.identifier)', UUID=\(region.uuid.uuidString)", category: .beacon)
                
                // FIX: Use centralized service to prevent conflicts
                unifiedLocationService.startMonitoring(for: region)
                unifiedLocationService.startRangingBeacons(in: region)
                
                registeredRegions.append(uniqueIdentifier)
                
                LoggerService.shared.debug("🔍 FIX: Scanning for UUID: \(uuidString) with unique ID: \(uniqueIdentifier)", category: .beacon)
            }
        }
        
        LoggerService.shared.info("📡 Registered \(registeredRegions.count) universal scan regions", category: .beacon)
        
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
        
        // FIX: Stop only our registered regions to avoid conflicts
        for regionId in registeredRegions {
            // Find and stop our regions
            let matchingRegions = unifiedLocationService.monitoredRegions.filter { region in
                region.identifier == regionId
            }
            
            for region in matchingRegions {
                if let beaconRegion = region as? CLBeaconRegion {
                    unifiedLocationService.stopMonitoring(for: beaconRegion)
                    unifiedLocationService.stopRangingBeacons(in: beaconRegion)
                    
                    LoggerService.shared.debug("🛑 FIX: Stopped universal scanning for: \(beaconRegion.identifier)", category: .beacon)
                }
            }
        }
        
        registeredRegions.removeAll()
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
    
    // FIX: Remove wildcard scanning as it's problematic and causes conflicts
    // Wildcard scanning often doesn't work and can cause region limit issues
    
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
            LoggerService.shared.warning("📡 No beacons detected in universal scan (\(registeredRegions.count) regions registered)", category: .beacon)
        }
    }
}

// MARK: - UnifiedBeaconDelegate (FIX: Use centralized delegate pattern)
extension UniversalBeaconScanner: UnifiedBeaconDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard isScanning else { return }
        
        // Only process callbacks for our registered regions
        guard registeredRegions.contains(region.identifier) else {
            // This callback is for another part of the app, ignore it
            return
        }
        
        // FIX: Comprehensive debug logging with empty identifier check
        LoggerService.shared.debug("🔍 FIX: UniversalScanner ranging callback via UnifiedLocationService", category: .beacon)
        LoggerService.shared.debug("📡 Region ID: '\(region.identifier)'", category: .beacon) 
        LoggerService.shared.debug("📡 Region UUID: \(region.uuid.uuidString)", category: .beacon)
        LoggerService.shared.debug("📡 Region Major: \(region.major?.stringValue ?? "nil")", category: .beacon)
        LoggerService.shared.debug("📡 Region Minor: \(region.minor?.stringValue ?? "nil")", category: .beacon)
        LoggerService.shared.debug("📡 Beacons count: \(beacons.count)", category: .beacon)
        
        // FIX: This should no longer happen with consolidated region management
        if region.identifier.isEmpty {
            LoggerService.shared.error("🚨 STILL CRITICAL: Region identifier is EMPTY even with fix! Investigate further!", category: .beacon)
            return
        }
        
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
                LoggerService.shared.info("🎯 FIX: FIRST BEACON DETECTED by UniversalScanner via UnifiedLocationService: UUID=\(beacon.uuid.uuidString)", category: .beacon)
            }
        }
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didEnterRegion region: CLBeaconRegion) {
        // Only process our registered regions
        guard registeredRegions.contains(region.identifier) else { return }
        
        LoggerService.shared.info("✅ FIX: UniversalScanner ENTERED region: \(region.identifier)", category: .beacon)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didExitRegion region: CLBeaconRegion) {
        // Only process our registered regions
        guard registeredRegions.contains(region.identifier) else { return }
        
        LoggerService.shared.info("⬅️ FIX: UniversalScanner EXITED region: \(region.identifier)", category: .beacon)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        // Only process our registered regions
        guard registeredRegions.contains(region.identifier) else { return }
        
        LoggerService.shared.debug("📊 FIX: UniversalScanner region state: \(region.identifier) -> \(state.rawValue)", category: .beacon)
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
