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

/// Time‑boxed ranging session (5–10s) using UnifiedLocationService
/// Optimized for battery efficiency with burst ranging mode
public final class ShortRanger: NSObject {
    
    // MARK: - Dependencies
    
    /// Unified location service for ranging operations
    private let unifiedLocationService: BeaconRangingProvider & UnifiedLocationProvider
    
    /// Current ranging session state
    private var activeRegions: [CLBeaconRegion] = []
    private var sessionTimer: Timer?
    private var sessionId: String?
    
    /// Delegate for ranging results
    public weak var delegate: ShortRangerDelegate?
    
    /// RSSI smoothing for more stable distance calculations
    private let smoother = RSSISmoother(window: 5)
    
    /// Session configuration
    private let defaultDuration: TimeInterval = 8.0
    private let snapshotInterval: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    /// Initialize with UnifiedLocationService (recommended)
    /// - Parameter unifiedLocationService: The unified location service to use
    public init(unifiedLocationService: (BeaconRangingProvider & UnifiedLocationProvider) = UnifiedLocationService.shared) {
        self.unifiedLocationService = unifiedLocationService
        super.init()
        
        // Register as beacon delegate if it's UnifiedLocationService
        if let unifiedService = unifiedLocationService as? UnifiedLocationService {
            unifiedService.addBeaconDelegate(self)
        }
        
        LoggerService.shared.info("✅ ShortRanger initialized with UnifiedLocationService", category: .beacon)
    }
    
    // MARK: - Ranging Session Management
    
    /// Start time-boxed ranging session with beacon identity constraints
    /// - Parameters:
    ///   - constraints: Array of beacon identity constraints to range for
    ///   - duration: Duration of ranging session (default: 8.0 seconds)
    public func start(constraints: [CLBeaconIdentityConstraint], duration: TimeInterval = 8.0) {
        // Stop any existing session
        stop()
        
        // Create session ID for tracking
        sessionId = "ranging_session_\(UUID().uuidString.prefix(8))"
        
        LoggerService.shared.info("🚀 Starting ShortRanger session (\(sessionId!)) - duration: \(duration)s", category: .beacon)
        
        // Convert constraints to regions and start ranging
        activeRegions.removeAll()
        for constraint in constraints {
            let region: CLBeaconRegion
            
            if #available(iOS 13.0, macOS 10.15, *) {
                region = constraint.asBeaconRegion()
            } else {
                // Fallback for older iOS versions
                let identifier = "constraint_\(constraint.uuid.uuidString.prefix(8))"
                region = CLBeaconRegion(uuid: constraint.uuid, identifier: identifier)
            }
            
            activeRegions.append(region)
            
            LoggerService.shared.debug("📡 Starting ranging for UUID: \(constraint.uuid.uuidString)", category: .beacon)
            unifiedLocationService.startRangingBeacons(in: region)
        }
        
        // Set up session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.finishSession()
        }
        
        LoggerService.shared.info("⚙️ ShortRanger session active - ranging \(activeRegions.count) regions", category: .beacon)
    }
    
    /// Stop current ranging session immediately
    public func stop() {
        guard !activeRegions.isEmpty else {
            LoggerService.shared.debug("⚠️ ShortRanger.stop() called but no active session", category: .beacon)
            return
        }
        
        LoggerService.shared.info("🛑 Stopping ShortRanger session (\(sessionId ?? "unknown"))", category: .beacon)
        
        // Stop ranging for all active regions
        for region in activeRegions {
            unifiedLocationService.stopRangingBeacons(in: region)
            LoggerService.shared.debug("🛑 Stopped ranging for: \(region.identifier)", category: .beacon)
        }
        
        // Clean up session state
        activeRegions.removeAll()
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionId = nil
    }
    
    /// Finish session and notify delegate
    private func finishSession() {
        let completedSessionId = sessionId
        LoggerService.shared.info("✅ ShortRanger session completed (\(completedSessionId ?? "unknown"))", category: .beacon)
        
        stop()
        
        // Create final snapshot with current smoothed data
        let finalSnapshot = createCurrentSnapshot()
        delegate?.didFinish(final: finalSnapshot)
    }
    
    /// Create snapshot of current ranging state
    private func createCurrentSnapshot() -> RangingSnapshot? {
        // This will be populated by delegate callbacks
        // For now, return nil as we don't maintain state here
        return nil
    }
}

// MARK: - CLBeaconIdentityConstraint Extension

@available(iOS 13.0, macOS 10.15, *)
private extension CLBeaconIdentityConstraint {
    
    /// Convert constraint to beacon region for ranging
    func asBeaconRegion() -> CLBeaconRegion {
        let identifier = "constraint_\(uuid.uuidString.prefix(8))"
        
        if let major = major, let minor = minor {
            return CLBeaconRegion(uuid: uuid, major: major, minor: minor, identifier: identifier)
        } else if let major = major {
            return CLBeaconRegion(uuid: uuid, major: major, identifier: identifier)
        } else {
            return CLBeaconRegion(uuid: uuid, identifier: identifier)
        }
    }
}

// MARK: - UnifiedBeaconDelegate

extension ShortRanger: UnifiedBeaconDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // Only process beacons if we're in an active ranging session
        guard sessionId != nil, activeRegions.contains(where: { $0.identifier == region.identifier }) else {
            return
        }
        
        // Smooth RSSI values for more stable distance calculations
        let smoothedBeacons = beacons.map { beacon -> CLBeacon in
            // Update smoother with new RSSI value
            let smoothedRSSI = smoother.value(for: beacon)
            
            // Create beacon with smoothed RSSI (if possible)
            // Note: CLBeacon properties are read-only, so we work with original beacon
            LoggerService.shared.debug("📡 Beacon: Major=\(beacon.major), Minor=\(beacon.minor), RSSI=\(beacon.rssi) → Smoothed: \(String(format: "%.1f", smoothedRSSI))", category: .beacon)
            return beacon
        }
        
        // Sort by smoothed RSSI (strongest first)
        let sortedBeacons = smoothedBeacons.sorted { beacon1, beacon2 in
            smoother.value(for: beacon1) > smoother.value(for: beacon2)
        }
        
        // Create snapshot with results
        let snapshot = RangingSnapshot(
            beacons: sortedBeacons,
            nearest: sortedBeacons.first
        )
        
        // Notify delegate of new snapshot
        delegate?.didProduce(snapshot: snapshot)
        
        if !beacons.isEmpty {
            LoggerService.shared.debug("📊 ShortRanger snapshot: \(beacons.count) beacons, nearest: Major=\(sortedBeacons.first?.major ?? 0), RSSI=\(sortedBeacons.first?.rssi ?? 0)", category: .beacon)
        }
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didEnterRegion region: CLBeaconRegion) {
        LoggerService.shared.debug("➡️ ShortRanger: Entered region \(region.identifier) during session", category: .beacon)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didExitRegion region: CLBeaconRegion) {
        LoggerService.shared.debug("⬅️ ShortRanger: Exited region \(region.identifier) during session", category: .beacon)
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        let stateString = state == .inside ? "INSIDE" : state == .outside ? "OUTSIDE" : "UNKNOWN"
        LoggerService.shared.debug("🎯 ShortRanger: State for \(region.identifier): \(stateString)", category: .beacon)
    }
}

