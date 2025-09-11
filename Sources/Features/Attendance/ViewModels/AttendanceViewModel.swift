//
//  AttendanceViewModel.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import Combine
import CoreLocation
import BeaconAttendanceCore

// MARK: - AttendanceViewState
public struct AttendanceViewState: ViewState {
    public let isLoading: Bool
    public let error: Error?
    public let currentSession: AttendanceSession?
    public let beaconStatus: BeaconStatus
    public let lastCheckInTime: Date?
    public let lastCheckOutTime: Date?
    public let todayStats: AttendanceStats?
    
    public init(
        isLoading: Bool = false,
        error: Error? = nil,
        currentSession: AttendanceSession? = nil,
        beaconStatus: BeaconStatus = .scanning,
        lastCheckInTime: Date? = nil,
        lastCheckOutTime: Date? = nil,
        todayStats: AttendanceStats? = nil
    ) {
        self.isLoading = isLoading
        self.error = error
        self.currentSession = currentSession
        self.beaconStatus = beaconStatus
        self.lastCheckInTime = lastCheckInTime
        self.lastCheckOutTime = lastCheckOutTime
        self.todayStats = todayStats
    }
    
    public static let initial = AttendanceViewState()
}

// MARK: - BeaconStatus
public enum BeaconStatus {
    case scanning
    case detected(rssi: Int)
    case inRange
    case outOfRange
    case disconnected
    
    var displayText: String {
        switch self {
        case .scanning: return "Scanning for beacons..."
        case .detected(let rssi): return "Beacon detected (RSSI: \(rssi))"
        case .inRange: return "In attendance zone"
        case .outOfRange: return "Out of range"
        case .disconnected: return "Disconnected"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .inRange, .detected: return true
        default: return false
        }
    }
}

// MARK: - AttendanceStats
public struct AttendanceStats {
    public let totalHours: TimeInterval
    public let checkIns: Int
    public let lastSync: Date?
    
    public init(totalHours: TimeInterval = 0, checkIns: Int = 0, lastSync: Date? = nil) {
        self.totalHours = totalHours
        self.checkIns = checkIns
        self.lastSync = lastSync
    }
}

// MARK: - AttendanceViewInput
public enum AttendanceViewInput {
    case refresh
    case manualCheckIn
    case manualCheckOut
    case exportLogs
    case syncData
    case toggleAutoMode(enabled: Bool)
}

// MARK: - AttendanceViewModel
public final class AttendanceViewModel: BaseViewModel<AttendanceViewState, AttendanceViewInput> {
    
    // Dependencies
    private let coordinator: AttendanceCoordinator
    private let sessionManager: SessionManager
    private let telemetryManager: TelemetryManager
    private let permissionManager: PermissionManager
    
    // Publishers
    private let beaconStatusSubject = CurrentValueSubject<BeaconStatus, Never>(.scanning)
    private let sessionSubject = CurrentValueSubject<AttendanceSession?, Never>(nil)
    
    // Timer for stats refresh
    private var statsTimer: Timer?
    
    public init(
        coordinator: AttendanceCoordinator,
        sessionManager: SessionManager,
        telemetryManager: TelemetryManager = .shared,
        permissionManager: PermissionManager
    ) {
        self.coordinator = coordinator
        self.sessionManager = sessionManager
        self.telemetryManager = telemetryManager
        self.permissionManager = permissionManager
        
        super.init(initialState: .initial)
    }
    
    // MARK: - Lifecycle
    
    public override func onAppear() {
        super.onAppear()
        setupObservers()
        refreshState()
        startStatsTimer()
    }
    
    public override func onDisappear() {
        super.onDisappear()
        stopStatsTimer()
    }
    
    // MARK: - Input Handling
    
    public override func handle(_ input: AttendanceViewInput) {
        switch input {
        case .refresh:
            refreshState()
            
        case .manualCheckIn:
            performManualCheckIn()
            
        case .manualCheckOut:
            performManualCheckOut()
            
        case .exportLogs:
            exportLogs()
            
        case .syncData:
            syncOfflineData()
            
        case .toggleAutoMode(let enabled):
            toggleAutoMode(enabled)
        }
    }
    
    // MARK: - Setup
    
    public override func setupBindings() {
        // Bind beacon status
        beaconStatusSubject
            .combineLatest(sessionSubject)
            .map { status, session in
                AttendanceViewState(
                    currentSession: session,
                    beaconStatus: status,
                    lastCheckInTime: session?.checkInTime,
                    todayStats: self.calculateTodayStats()
                )
            }
            .assign(to: &$state)
        
        // Monitor session changes
        NotificationCenter.default.publisher(for: .attendanceSessionChanged)
            .compactMap { $0.object as? AttendanceSession }
            .sink { [weak self] session in
                self?.sessionSubject.send(session)
            }
            .store(in: &cancellables)
        
        // Monitor beacon status
        NotificationCenter.default.publisher(for: .beaconStatusChanged)
            .compactMap { $0.userInfo?["status"] as? BeaconStatus }
            .sink { [weak self] status in
                self?.beaconStatusSubject.send(status)
            }
            .store(in: &cancellables)
    }
    
    private func setupObservers() {
        // Observe permission changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkPermissions()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func refreshState() {
        setLoading(true)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            do {
                // Get current session
                let session = self.sessionManager.getCurrentSession()
                self.sessionSubject.send(session)
                
                // Update stats
                let stats = self.calculateTodayStats()
                
                // Update state
                self.updateState(AttendanceViewState(
                    currentSession: session,
                    beaconStatus: self.beaconStatusSubject.value,
                    lastCheckInTime: session?.checkInTime,
                    todayStats: stats
                ))
                
                self.setLoading(false)
                
            } catch {
                self.setLoading(false)
                self.handleError(error)
            }
        }
    }
    
    private func performManualCheckIn() {
        guard sessionSubject.value == nil else {
            handleError(AppError.sessionAlreadyExists)
            return
        }
        
        executeWithLoading(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown(NSError()) }
                
                // Create manual check-in
                let sessionId = UUID().uuidString
                let session = AttendanceSession(
                    sessionKey: sessionId,
                    userId: "current_user", // Get from auth
                    siteId: "manual",
                    checkInTime: Date(),
                    checkOutTime: nil,
                    status: .active
                )
                
                // Track telemetry
                self.telemetryManager.track(
                    .checkIn,
                    sessionId: sessionId,
                    siteId: "manual",
                    metadata: ["type": "manual"]
                )
                
                return session
            },
            onSuccess: { [weak self] session in
                self?.sessionSubject.send(session)
                EnhancedLogger.shared.info("Manual check-in successful", category: .session)
            }
        )
    }
    
    private func performManualCheckOut() {
        guard let session = sessionSubject.value else {
            handleError(AppError.noActiveSession)
            return
        }
        
        executeWithLoading(
            operation: { [weak self] in
                guard let self = self else { throw AppError.unknown(NSError()) }
                
                // End session
                self.sessionManager.endSession()
                
                // Track telemetry
                self.telemetryManager.track(
                    .checkOut,
                    sessionId: session.sessionKey,
                    siteId: session.siteId,
                    metadata: ["type": "manual"]
                )
                
                return true
            },
            onSuccess: { [weak self] _ in
                self?.sessionSubject.send(nil)
                EnhancedLogger.shared.info("Manual check-out successful", category: .session)
            }
        )
    }
    
    private func exportLogs() {
        if let logURL = EnhancedLogger.shared.exportLogs() {
            // Share logs
            NotificationCenter.default.post(
                name: .shareLogs,
                object: logURL
            )
            
            telemetryManager.track(
                .exportLogs,
                metadata: ["source": "attendance_view"]
            )
        }
    }
    
    private func syncOfflineData() {
        executeWithLoading(
            operation: { [weak self] in
                // Sync with server
                try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate
                return true
            },
            onSuccess: { _ in
                EnhancedLogger.shared.info("Data sync completed", category: .network)
            }
        )
    }
    
    private func toggleAutoMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "auto_attendance_enabled")
        
        telemetryManager.track(
            .settingChanged,
            metadata: [
                "setting": "auto_mode",
                "value": String(enabled)
            ]
        )
    }
    
    private func calculateTodayStats() -> AttendanceStats {
        // Calculate today's attendance stats
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get sessions for today (mock for now)
        let totalHours: TimeInterval = 7.5 * 3600 // Mock 7.5 hours
        let checkIns = 1
        
        return AttendanceStats(
            totalHours: totalHours,
            checkIns: checkIns,
            lastSync: Date()
        )
    }
    
    private func checkPermissions() {
        Task { @MainActor [weak self] in
            let hasLocation = self?.permissionManager.hasLocationPermission() ?? false
            let hasNotification = self?.permissionManager.hasNotificationPermission() ?? false
            
            if !hasLocation {
                self?.handleError(AppError.locationPermissionDenied)
            }
            
            EnhancedLogger.shared.debug(
                "Permissions check",
                category: .security,
                metadata: [
                    "location": String(hasLocation),
                    "notification": String(hasNotification)
                ]
            )
        }
    }
    
    // MARK: - Timer Management
    
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshState()
        }
    }
    
    private func stopStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = nil
    }
}

// MARK: - Notification Names
public extension Notification.Name {
    static let attendanceSessionChanged = Notification.Name("attendanceSessionChanged")
    static let beaconStatusChanged = Notification.Name("beaconStatusChanged")
    static let shareLogs = Notification.Name("shareLogs")
}
