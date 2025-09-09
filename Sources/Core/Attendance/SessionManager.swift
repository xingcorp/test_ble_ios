//
//  SessionManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

/// Manages active attendance sessions
public final class SessionManager {
    private let store: KeyValueStore
    private let userId: String
    private var activeSession: LocalSession?
    
    private let sessionKey = AppConstants.Storage.activeSessionKey
    
    public init(store: KeyValueStore, userId: String) {
        self.store = store
        self.userId = userId
        loadActiveSession()
    }
    
    public func createSession(for siteId: String) -> String {
        let sessionId = generateSessionId()
        let session = LocalSession(
            sessionKey: sessionId,
            siteId: siteId,
            userId: userId,
            start: Date()
        )
        
        activeSession = session
        saveSession(session)
        
        return sessionId
    }
    
    public func getCurrentSession() -> LocalSession? {
        return activeSession
    }
    
    public func endSession() {
        activeSession?.end = Date()
        if let session = activeSession {
            saveSession(session)
        }
        activeSession = nil
    }
    
    public func updateHeartbeat() {
        activeSession?.lastHeartbeat = Date()
        if let session = activeSession {
            saveSession(session)
        }
    }
    
    private func loadActiveSession() {
        guard let data = store.get(sessionKey),
              let session = try? JSONDecoder().decode(LocalSession.self, from: data),
              session.end == nil else {
            return
        }
        activeSession = session
    }
    
    private func saveSession(_ session: LocalSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        store.set(data, for: sessionKey)
    }
    
    private func generateSessionId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "\(userId)-\(timestamp)-\(random)"
    }
}
