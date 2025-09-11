//
//  BeaconScannerViewModel.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import Combine
import CoreLocation
import BeaconAttendanceCore

/// ViewModel for beacon scanning feature following MVVM pattern
public final class BeaconScannerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var scanState: ScanState = .idle
    @Published public private(set) var detectedBeacons: [BeaconInfo] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var scanDuration: TimeInterval = 0
    @Published public private(set) var lastError: Error?
    @Published public private(set) var selectedFilter: BeaconFilter = .all
    @Published public private(set) var sortOption: SortOption = .bySignal
    
    // MARK: - Types
    
    public enum ScanState: Equatable {
        case idle
        case scanning
        case completed(count: Int)
        case error(String)
    }
    
    public enum BeaconFilter: String, CaseIterable {
        case all = "All"
        case configured = "Configured Only"
        case unknown = "Unknown Only"
        case nearbyOnly = "Nearby (<5m)"
        
        var displayName: String { rawValue }
    }
    
    public enum SortOption: String, CaseIterable {
        case bySignal = "Signal Strength"
        case byDistance = "Distance"
        case byUUID = "UUID"
        case byLastSeen = "Last Seen"
        
        var displayName: String { rawValue }
    }
    
    public struct BeaconInfo: Identifiable, Equatable {
        public let id = UUID()
        public let uuid: String
        public let major: Int
        public let minor: Int
        public var rssi: Int
        public var distance: Double
        public var lastSeen: Date
        public var proximity: String
        public var isConfigured: Bool
        
        var signalStrength: String {
            if rssi >= -50 { return "Excellent" }
            if rssi >= -60 { return "Good" }
            if rssi >= -70 { return "Fair" }
            return "Poor"
        }
        
        var formattedDistance: String {
            if distance < 0 { return "Unknown" }
            if distance < 1 { return String(format: "%.1f cm", distance * 100) }
            return String(format: "%.1f m", distance)
        }
    }
    
    // MARK: - Private Properties
    
    private let scanner: UniversalBeaconScanner
    private let logger: LoggerService
    private let configuredUUID: String
    private var cancellables = Set<AnyCancellable>()
    private var scanTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Initialization
    
    public init(
        scanner: UniversalBeaconScanner = .shared,
        logger: LoggerService = .shared,
        configuredUUID: String = AppConfiguration.shared.beacon.defaultUUID
    ) {
        self.scanner = scanner
        self.logger = logger
        self.configuredUUID = configuredUUID
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    public func startScanning(duration: TimeInterval = 30) {
        guard !isScanning else { return }
        
        logger.info("🔍 Starting beacon scan for \(duration) seconds", category: .beacon)
        
        isScanning = true
        scanState = .scanning
        detectedBeacons.removeAll()
        lastError = nil
        startTime = Date()
        scanDuration = 0
        
        // Setup scanner callback
        scanner.onBeaconsDetected = { [weak self] beacons in
            self?.processDetectedBeacons(beacons)
        }
        
        // Start scanning
        scanner.startUniversalScan()
        
        // Setup timer for duration update
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.scanDuration = Date().timeIntervalSince(startTime)
            
            if self.scanDuration >= duration {
                self.stopScanning()
            }
        }
    }
    
    public func stopScanning() {
        guard isScanning else { return }
        
        logger.info("⏹️ Stopping beacon scan", category: .beacon)
        
        scanner.stopUniversalScan()
        scanTimer?.invalidate()
        scanTimer = nil
        isScanning = false
        
        let count = detectedBeacons.count
        scanState = .completed(count: count)
        
        if count == 0 {
            logger.warning("No beacons detected during scan", category: .beacon)
        } else {
            logger.info("✅ Scan completed: \(count) beacon(s) found", category: .beacon)
        }
    }
    
    public func applyFilter(_ filter: BeaconFilter) {
        selectedFilter = filter
        refreshBeaconList()
    }
    
    public func applySorting(_ option: SortOption) {
        sortOption = option
        sortBeacons()
    }
    
    public func exportLogs() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let fileName = "beacon_scan_\(timestamp).json"
        
        let exportData = BeaconScanExport(
            timestamp: Date(),
            duration: scanDuration,
            beaconsFound: detectedBeacons.count,
            configuredUUID: configuredUUID,
            beacons: detectedBeacons.map { beacon in
                BeaconScanExport.BeaconData(
                    uuid: beacon.uuid,
                    major: beacon.major,
                    minor: beacon.minor,
                    rssi: beacon.rssi,
                    distance: beacon.distance,
                    lastSeen: beacon.lastSeen,
                    proximity: beacon.proximity,
                    signalStrength: beacon.signalStrength
                )
            }
        )
        
        guard let data = try? JSONEncoder().encode(exportData) else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        
        logger.info("📤 Exported scan results to: \(fileName)", category: .beacon)
        return tempURL
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Auto-refresh beacon list every second when scanning
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard self?.isScanning == true else { return }
                self?.refreshBeaconList()
            }
            .store(in: &cancellables)
    }
    
    private func processDetectedBeacons(_ beacons: [DetectedBeacon]) {
        for beacon in beacons {
            updateOrAddBeacon(beacon)
        }
        
        refreshBeaconList()
    }
    
    private func updateOrAddBeacon(_ detected: DetectedBeacon) {
        let isConfigured = detected.uuid.uppercased() == configuredUUID.uppercased()
        
        let proximity: String
        if detected.distance < 1 { proximity = "Immediate" }
        else if detected.distance < 5 { proximity = "Near" }
        else if detected.distance < 30 { proximity = "Far" }
        else { proximity = "Unknown" }
        
        let beaconInfo = BeaconInfo(
            uuid: detected.uuid,
            major: detected.major,
            minor: detected.minor,
            rssi: detected.rssi,
            distance: detected.distance,
            lastSeen: detected.lastSeen,
            proximity: proximity,
            isConfigured: isConfigured
        )
        
        if let index = detectedBeacons.firstIndex(where: {
            $0.uuid == detected.uuid && $0.major == detected.major && $0.minor == detected.minor
        }) {
            detectedBeacons[index] = beaconInfo
        } else {
            detectedBeacons.append(beaconInfo)
            logger.info("🆕 New beacon detected: \(detected.uuid)", category: .beacon)
        }
    }
    
    private func refreshBeaconList() {
        // Apply filter
        var filtered = detectedBeacons
        
        switch selectedFilter {
        case .all:
            break
        case .configured:
            filtered = filtered.filter { $0.isConfigured }
        case .unknown:
            filtered = filtered.filter { !$0.isConfigured }
        case .nearbyOnly:
            filtered = filtered.filter { $0.distance < 5 && $0.distance > 0 }
        }
        
        // Remove stale beacons (not seen in last 5 seconds)
        let now = Date()
        filtered = filtered.filter { now.timeIntervalSince($0.lastSeen) < 5 }
        
        detectedBeacons = filtered
        sortBeacons()
    }
    
    private func sortBeacons() {
        switch sortOption {
        case .bySignal:
            detectedBeacons.sort { $0.rssi > $1.rssi }
        case .byDistance:
            detectedBeacons.sort { $0.distance < $1.distance }
        case .byUUID:
            detectedBeacons.sort { $0.uuid < $1.uuid }
        case .byLastSeen:
            detectedBeacons.sort { $0.lastSeen > $1.lastSeen }
        }
    }
}

// MARK: - Export Model

private struct BeaconScanExport: Codable {
    let timestamp: Date
    let duration: TimeInterval
    let beaconsFound: Int
    let configuredUUID: String
    let beacons: [BeaconData]
    
    struct BeaconData: Codable {
        let uuid: String
        let major: Int
        let minor: Int
        let rssi: Int
        let distance: Double
        let lastSeen: Date
        let proximity: String
        let signalStrength: String
    }
}
