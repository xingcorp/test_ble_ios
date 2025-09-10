//
//  AttendanceService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Concrete implementation of AttendanceServiceProtocol
public final class AttendanceService: AttendanceServiceProtocol {
    
    // MARK: - Properties
    
    private var currentSession: AttendanceSession?
    private let sessionStorage: SessionStorage
    private let networkService: NetworkService
    private let userId: String
    
    // MARK: - Initialization
    
    public init(userId: String) {
        self.userId = userId
        self.sessionStorage = SessionStorage()
        self.networkService = NetworkService()
        
        // Load current session if exists
        self.currentSession = sessionStorage.loadCurrentSession()
    }
    
    // MARK: - AttendanceServiceProtocol
    
    public func checkIn(at location: CLLocation?, beaconId: String?) async throws -> AttendanceSession {
        // Check if already checked in
        if let session = currentSession, session.isActive {
            throw AttendanceError.alreadyCheckedIn
        }
        
        // Create new session
        let session = AttendanceSession(
            userId: userId,
            checkInLocation: location.map { Location(from: $0) },
            beaconId: beaconId
        )
        
        // Save locally
        currentSession = session
        try sessionStorage.saveSession(session)
        
        // Sync with server
        do {
            try await networkService.checkIn(session: session)
            LoggerService.shared.info("Check-in successful: \(session.id)")
        } catch {
            LoggerService.shared.warning("Check-in failed to sync, saved offline: \(error.localizedDescription)")
            // Mark for offline sync
            try sessionStorage.markForSync(sessionId: session.id)
        }
        
        return session
    }
    
    public func checkOut(sessionId: String) async throws {
        guard var session = currentSession, session.id == sessionId else {
            throw AttendanceError.sessionNotFound
        }
        
        // Update session
        session.checkOutTime = Date()
        if let location = try? await LocationManager.shared.getCurrentLocation() {
            session.checkOutLocation = Location(from: location)
        }
        
        // Save locally
        currentSession = nil
        try sessionStorage.saveSession(session)
        
        // Sync with server
        do {
            try await networkService.checkOut(session: session)
            LoggerService.shared.info("Check-out successful: \(session.id)")
        } catch {
            LoggerService.shared.warning("Check-out failed to sync, saved offline: \(error.localizedDescription)")
            // Mark for offline sync
            try sessionStorage.markForSync(sessionId: session.id)
        }
    }
    
    public func getCurrentSession() -> AttendanceSession? {
        return currentSession
    }
    
    public func getSessions(from startDate: Date, to endDate: Date) async throws -> [AttendanceSession] {
        // Try to fetch from server first
        do {
            let sessions = try await networkService.fetchSessions(userId: userId, from: startDate, to: endDate)
            // Cache locally
            for session in sessions {
                try sessionStorage.saveSession(session)
            }
            return sessions
        } catch {
            // Fallback to local data
            LoggerService.shared.warning("Failed to fetch sessions from server, using local data")
            return sessionStorage.loadSessions(from: startDate, to: endDate)
        }
    }
    
    public func syncOfflineSessions() async throws {
        let offlineSessions = sessionStorage.getOfflineSessions()
        
        for session in offlineSessions {
            do {
                if session.isActive {
                    try await networkService.checkIn(session: session)
                } else {
                    try await networkService.checkOut(session: session)
                }
                try sessionStorage.markAsSynced(sessionId: session.id)
                LoggerService.shared.info("Synced offline session: \(session.id)")
            } catch {
                LoggerService.shared.error("Failed to sync session \(session.id)", error: error)
            }
        }
    }
    
    public func validateBeacon(_ beaconId: String) async throws -> Bool {
        do {
            return try await networkService.validateBeacon(beaconId)
        } catch {
            LoggerService.shared.warning("Failed to validate beacon online: \(error.localizedDescription)")
            // Fallback to offline validation
            return AppConfiguration.shared.beacon.defaultUUID == beaconId
        }
    }
}

// MARK: - Session Storage

private class SessionStorage {
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "attendance.sessions"
    private let currentSessionKey = "attendance.current"
    private let offlineSessionsKey = "attendance.offline"
    
    func saveSession(_ session: AttendanceSession) throws {
        var sessions = loadAllSessions()
        sessions[session.id] = session
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(sessions)
        userDefaults.set(data, forKey: sessionsKey)
        
        if session.isActive {
            let currentData = try encoder.encode(session)
            userDefaults.set(currentData, forKey: currentSessionKey)
        } else {
            userDefaults.removeObject(forKey: currentSessionKey)
        }
    }
    
    func loadCurrentSession() -> AttendanceSession? {
        guard let data = userDefaults.data(forKey: currentSessionKey) else { return nil }
        return try? JSONDecoder().decode(AttendanceSession.self, from: data)
    }
    
    func loadSessions(from startDate: Date, to endDate: Date) -> [AttendanceSession] {
        let sessions = loadAllSessions()
        return sessions.values.filter { session in
            session.checkInTime >= startDate && session.checkInTime <= endDate
        }.sorted { $0.checkInTime > $1.checkInTime }
    }
    
    func loadAllSessions() -> [String: AttendanceSession] {
        guard let data = userDefaults.data(forKey: sessionsKey) else { return [:] }
        return (try? JSONDecoder().decode([String: AttendanceSession].self, from: data)) ?? [:]
    }
    
    func markForSync(sessionId: String) throws {
        var offlineIds = userDefaults.stringArray(forKey: offlineSessionsKey) ?? []
        if !offlineIds.contains(sessionId) {
            offlineIds.append(sessionId)
            userDefaults.set(offlineIds, forKey: offlineSessionsKey)
        }
    }
    
    func markAsSynced(sessionId: String) throws {
        var offlineIds = userDefaults.stringArray(forKey: offlineSessionsKey) ?? []
        offlineIds.removeAll { $0 == sessionId }
        userDefaults.set(offlineIds, forKey: offlineSessionsKey)
    }
    
    func getOfflineSessions() -> [AttendanceSession] {
        let offlineIds = userDefaults.stringArray(forKey: offlineSessionsKey) ?? []
        let allSessions = loadAllSessions()
        return offlineIds.compactMap { allSessions[$0] }
    }
}

// MARK: - Network Service (Stub)

private class NetworkService {
    func checkIn(session: AttendanceSession) async throws {
        // TODO: Implement actual network call
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate network delay
    }
    
    func checkOut(session: AttendanceSession) async throws {
        // TODO: Implement actual network call
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate network delay
    }
    
    func fetchSessions(userId: String, from: Date, to: Date) async throws -> [AttendanceSession] {
        // TODO: Implement actual network call
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate network delay
        return []
    }
    
    func validateBeacon(_ beaconId: String) async throws -> Bool {
        // TODO: Implement actual network call
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate network delay
        return true
    }
}
