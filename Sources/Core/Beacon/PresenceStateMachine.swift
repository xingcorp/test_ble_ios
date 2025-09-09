//
//  PresenceStateMachine.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public enum PresenceState: Equatable {
    case idle
    case inside(siteId: String)
    case softExitPending(siteId: String, startedAt: Date)
}

public protocol PresenceActions: AnyObject {
    func checkIn(siteId: String, reason: String)
    func checkOut(siteId: String, reason: String)
}

/// Drives business decisions across enter/exit, ranging, and grace windows.
public final class PresenceStateMachine {
    private(set) public var state: PresenceState = .idle
    private let now: () -> Date
    private var graceTimer: Timer?
    public weak var actions: PresenceActions?
    
    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }
    
    public func onEnter(siteId: String) {
        switch state {
        case .inside(let s) where s == siteId:
            break // Already inside same site
        default:
            state = .inside(siteId: siteId)
            actions?.checkIn(siteId: siteId, reason: "enter-region")
        }
    }
    
    public func onRangingSoftExitSignal(for siteId: String, graceSeconds: TimeInterval = 45) {
        guard case .inside(let s) = state, s == siteId else { return }
        state = .softExitPending(siteId: siteId, startedAt: now())
        startGraceTimer(seconds: graceSeconds)
    }
    
    public func onConfirmedExit(siteId: String) {
        switch state {
        case .inside(let s) where s == siteId,
             .softExitPending(let s, _) where s == siteId:
            commitExit(for: siteId, reason: "exit-region")
        default:
            break
        }
    }
    
    public func cancelSoftExitIfBackInside(siteId: String) {
        if case .softExitPending(let s, _) = state, s == siteId {
            invalidateGrace()
            state = .inside(siteId: siteId)
        }
    }
    
    private func startGraceTimer(seconds: TimeInterval) {
        invalidateGrace()
        graceTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if case .softExitPending(let siteId, _) = self.state {
                self.commitExit(for: siteId, reason: "soft-exit-grace")
            }
        }
    }
    
    private func invalidateGrace() {
        graceTimer?.invalidate()
        graceTimer = nil
    }
    
    private func commitExit(for siteId: String, reason: String) {
        invalidateGrace()
        state = .idle
        actions?.checkOut(siteId: siteId, reason: reason)
    }
}
