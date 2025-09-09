//
//  AttendanceCoordinator.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Orchestrates the entire attendance flow
public final class AttendanceCoordinator {
    
    // Dependencies
    private let regionManager: BeaconRegionManager
    private let ranger: ShortRanger
    private let presenceStateMachine: PresenceStateMachine
    private let sessionManager: SessionManager
    private let sink: AttendanceSink
    private let slcsService: SLCSService
    
    // State
    private var isRanging = false
    private var lastRangingTime: Date?
    private let rangingDebounceInterval: TimeInterval = 30 // Prevent rapid ranging
    
    public init(
        regionManager: BeaconRegionManager,
        ranger: ShortRanger,
        presenceStateMachine: PresenceStateMachine,
        sessionManager: SessionManager,
        sink: AttendanceSink,
        slcsService: SLCSService
    ) {
        self.regionManager = regionManager
        self.ranger = ranger
        self.presenceStateMachine = presenceStateMachine
        self.sessionManager = sessionManager
        self.sink = sink
        self.slcsService = slcsService
        
        setupDelegates()
    }
    
    private func setupDelegates() {
        regionManager.delegate = self
        ranger.delegate = self
        presenceStateMachine.actions = self
        slcsService.delegate = self
    }
    
    // MARK: - Public Methods
    
    public func start(sites: [SiteRegion]) {
        Logger.info("Starting attendance coordinator with \(sites.count) sites")
        regionManager.configure(with: sites)
        slcsService.start()
    }
    
    public func stop() {
        Logger.info("Stopping attendance coordinator")
        slcsService.stop()
        ranger.stop()
    }
}

// MARK: - BeaconRegionManagerDelegate

extension AttendanceCoordinator: BeaconRegionManagerDelegate {
    
    public func didEnter(siteId: String) {
        Logger.info("🟢 Did enter site: \(siteId)")
        
        // Notify state machine
        presenceStateMachine.onEnter(siteId: siteId)
        
        // Start ranging if not already
        startRangingIfNeeded(for: siteId)
    }
    
    public func didExit(siteId: String) {
        Logger.info("🔴 Did exit site: \(siteId)")
        
        // Stop any active ranging
        if isRanging {
            ranger.stop()
            isRanging = false
        }
        
        // Notify state machine
        presenceStateMachine.onConfirmedExit(siteId: siteId)
    }
    
    public func didDetermine(siteId: String, inside: Bool) {
        Logger.info("📍 Determined state for \(siteId): \(inside ? "INSIDE" : "OUTSIDE")")
        
        if inside {
            // Re-evaluate presence
            presenceStateMachine.onEnter(siteId: siteId)
            startRangingIfNeeded(for: siteId)
        } else {
            // Confirm we're really outside
            if case .softExitPending(let pendingSite, _) = presenceStateMachine.state,
               pendingSite == siteId {
                // We're in soft-exit and confirmed outside
                presenceStateMachine.onConfirmedExit(siteId: siteId)
            }
        }
    }
    
    private func startRangingIfNeeded(for siteId: String) {
        // Debounce ranging
        if let lastTime = lastRangingTime,
           Date().timeIntervalSince(lastTime) < rangingDebounceInterval {
            Logger.info("Skipping ranging - too soon since last ranging")
            return
        }
        
        guard !isRanging else { return }
        
        Logger.info("Starting ranging burst for site: \(siteId)")
        isRanging = true
        lastRangingTime = Date()
        
        // Create constraint for the site's UUID and major
        // For now using default UUID - in production, look up from site config
        let constraint = CLBeaconIdentityConstraint(
            uuid: SiteRegion.defaultUUID,
            major: 100 // TODO: Get from site config
        )
        
        ranger.start(constraints: [constraint], duration: 8.0)
    }
}

// MARK: - ShortRangerDelegate

extension AttendanceCoordinator: ShortRangerDelegate {
    
    public func didProduce(snapshot: RangingSnapshot) {
        let beaconCount = snapshot.beacons.count
        let nearestRSSI = snapshot.nearest?.rssi ?? -100
        
        Logger.info("Ranging snapshot: \(beaconCount) beacons, nearest RSSI: \(nearestRSSI)")
        
        // Check for soft-exit condition
        if beaconCount == 0 || nearestRSSI < -85 {
            handleWeakSignal()
        } else {
            handleStrongSignal()
        }
    }
    
    public func didFinish(final: RangingSnapshot?) {
        Logger.info("Ranging finished")
        isRanging = false
        
        // Final evaluation
        if let snapshot = final, snapshot.beacons.isEmpty {
            handleWeakSignal()
        }
    }
    
    private func handleWeakSignal() {
        if case .inside(let siteId) = presenceStateMachine.state {
            Logger.warn("Weak/no signal detected - initiating soft-exit")
            presenceStateMachine.onRangingSoftExitSignal(for: siteId, graceSeconds: 45)
        }
    }
    
    private func handleStrongSignal() {
        if case .softExitPending(let siteId, _) = presenceStateMachine.state {
            Logger.info("Strong signal restored - canceling soft-exit")
            presenceStateMachine.cancelSoftExitIfBackInside(siteId: siteId)
        }
    }
}

// MARK: - PresenceActions

extension AttendanceCoordinator: PresenceActions {
    
    public func checkIn(siteId: String, reason: String) {
        Logger.info("✅ CHECK-IN: site=\(siteId), reason=\(reason)")
        
        let sessionId = sessionManager.createSession(for: siteId)
        let timestamp = Date()
        
        sink.handleCheckIn(
            sessionId: sessionId,
            siteId: siteId,
            timestamp: timestamp
        )
    }
    
    public func checkOut(siteId: String, reason: String) {
        Logger.info("👋 CHECK-OUT: site=\(siteId), reason=\(reason)")
        
        guard let session = sessionManager.getCurrentSession() else {
            Logger.error("No active session to check out")
            return
        }
        
        let timestamp = Date()
        sessionManager.endSession()
        
        sink.handleCheckOut(
            sessionId: session.sessionKey,
            siteId: siteId,
            timestamp: timestamp,
            reason: reason
        )
    }
}

// MARK: - SLCSServiceDelegate

extension AttendanceCoordinator: SLCSServiceDelegate {
    
    public func didTriggerSignificantChange() {
        Logger.info("📍 Significant location change detected - re-evaluating presence")
        
        // Re-request state for all monitored regions
        // This helps catch missed exits when user moves far away
        regionManager.regions.forEach { (_, region) in
            regionManager.manager.requestState(for: region)
        }
    }
}
