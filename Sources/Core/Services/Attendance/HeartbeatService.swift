//
//  HeartbeatService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
#if canImport(UIKit)
import UIKit
import BackgroundTasks
#endif

/// Delegate protocol for heartbeat service events
public protocol HeartbeatServiceDelegate: AnyObject {
    func heartbeatServiceDidTrigger()
}

/// Service that sends periodic heartbeats to keep sessions alive
/// Handles both foreground and background heartbeats
public final class HeartbeatService {
    
    // MARK: - Properties
    
    public weak var delegate: HeartbeatServiceDelegate?
    
    private var heartbeatTimer: Timer?
    #if canImport(UIKit)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif
    private var lastHeartbeatTime: Date?
    
    // Configuration
    private let foregroundInterval: TimeInterval = 60.0 // 1 minute in foreground
    private let backgroundInterval: TimeInterval = 180.0 // 3 minutes in background
    private let sessionTTL: TimeInterval = 300.0 // 5 minutes TTL on server
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.oxii.attendance.heartbeat"
    
    // State tracking
    private var isActive = false
    private var isInBackground = false
    
    // MARK: - Initialization
    
    public init() {
        setupLifecycleObservers()
        registerBackgroundTask()
        LoggerService.shared.info("✅ HeartbeatService initialized", category: .background)
    }
    
    // MARK: - Public Methods
    
    /// Start sending heartbeats
    public func start() {
        guard !isActive else { 
            LoggerService.shared.debug("HeartbeatService already active", category: .background)
            return 
        }
        
        isActive = true
        lastHeartbeatTime = Date()
        
        // Send initial heartbeat immediately
        sendHeartbeat()
        
        // Schedule periodic heartbeats
        scheduleHeartbeat()
        
        LoggerService.shared.info("💓 HeartbeatService started", category: .background)
    }
    
    /// Stop sending heartbeats
    public func stop() {
        guard isActive else { 
            LoggerService.shared.debug("HeartbeatService not active", category: .background)
            return 
        }
        
        isActive = false
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        // End any active background task
        #if canImport(UIKit)
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        #endif
        
        LoggerService.shared.info("💔 HeartbeatService stopped", category: .background)
    }
    
    /// Force send a heartbeat immediately (useful for critical events)
    public func sendImmediateHeartbeat() {
        guard isActive else { return }
        sendHeartbeat()
    }
    
    /// Check if heartbeat is overdue (for recovery scenarios)
    public func isHeartbeatOverdue() -> Bool {
        guard let lastTime = lastHeartbeatTime else { return true }
        return Date().timeIntervalSince(lastTime) > sessionTTL
    }
    
    // MARK: - Private Methods
    
    private func setupLifecycleObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #endif
    }
    
    private func registerBackgroundTask() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: backgroundTaskIdentifier,
                using: nil
            ) { [weak self] task in
                self?.handleBackgroundTask(task)
            }
        }
        #endif
    }
    
    private func scheduleHeartbeat() {
        heartbeatTimer?.invalidate()
        
        let interval = isInBackground ? backgroundInterval : foregroundInterval
        
        heartbeatTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.sendHeartbeat()
        }
        
        LoggerService.shared.debug("Scheduled heartbeat with interval: \(interval)s", category: .background)
    }
    
    private func sendHeartbeat() {
        lastHeartbeatTime = Date()
        
        // Notify delegate
        delegate?.heartbeatServiceDidTrigger()
        
        LoggerService.shared.debug("💓 Heartbeat sent at \(Date())", category: .background)
        
        // If in background, schedule next background task
        if isInBackground {
            scheduleBackgroundHeartbeat()
        }
    }
    
    private func scheduleBackgroundHeartbeat() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundInterval)
            
            do {
                try BGTaskScheduler.shared.submit(request)
                LoggerService.shared.debug("Scheduled background heartbeat task", category: .background)
            } catch {
                LoggerService.shared.error("Failed to schedule background heartbeat", error: error, category: .background)
            }
        }
        #endif
    }
    
    #if canImport(UIKit)
    @available(iOS 13.0, *)
    private func handleBackgroundTask(_ task: BGTask) {
        LoggerService.shared.info("🎯 Background heartbeat task triggered", category: .background)
        
        // Schedule next background task
        scheduleBackgroundHeartbeat()
        
        // Create a background task to ensure we complete
        let bgTask = UIApplication.shared.beginBackgroundTask {
            task.setTaskCompleted(success: false)
        }
        
        // Send heartbeat
        if isActive {
            sendHeartbeat()
        }
        
        // Mark task as complete
        task.setTaskCompleted(success: true)
        
        // End background task
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
        }
    }
    #endif
    
    // MARK: - Lifecycle Handlers
    
    @objc private func appDidEnterBackground() {
        isInBackground = true
        
        guard isActive else { return }
        
        LoggerService.shared.info("App entering background - adjusting heartbeat", category: .background)
        
        #if canImport(UIKit)
        // Begin background task to ensure we can send heartbeats
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.handleBackgroundExpiration()
        }
        #endif
        
        // Send immediate heartbeat before going to background
        sendHeartbeat()
        
        // Reschedule with background interval
        scheduleHeartbeat()
    }
    
    @objc private func appWillEnterForeground() {
        isInBackground = false
        
        guard isActive else { return }
        
        LoggerService.shared.info("App entering foreground - adjusting heartbeat", category: .background)
        
        #if canImport(UIKit)
        // End background task if active
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        #endif
        
        // Check if heartbeat is overdue
        if isHeartbeatOverdue() {
            LoggerService.shared.warning("⚠️ Heartbeat overdue - sending immediate heartbeat", category: .background)
            sendHeartbeat()
        }
        
        // Reschedule with foreground interval
        scheduleHeartbeat()
    }
    
    private func handleBackgroundExpiration() {
        LoggerService.shared.warning("⚠️ Background task expiring - last heartbeat attempt", category: .background)
        
        // Send one last heartbeat
        if isActive {
            sendHeartbeat()
        }
        
        #if canImport(UIKit)
        // Clean up
        backgroundTask = .invalid
        #endif
    }
    
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Session TTL Management

public extension HeartbeatService {
    
    /// Configuration for server-side TTL handling
    struct TTLConfiguration {
        /// Maximum time between heartbeats before session is considered stale
        public let maxHeartbeatInterval: TimeInterval
        
        /// Grace period before force checkout
        public let graceInterval: TimeInterval
        
        /// Whether to auto-checkout stale sessions
        public let autoCheckoutEnabled: Bool
        
        public init(
            maxHeartbeatInterval: TimeInterval = 300, // 5 minutes
            graceInterval: TimeInterval = 60, // 1 minute grace
            autoCheckoutEnabled: Bool = true
        ) {
            self.maxHeartbeatInterval = maxHeartbeatInterval
            self.graceInterval = graceInterval
            self.autoCheckoutEnabled = autoCheckoutEnabled
        }
    }
    
    /// Get recommended TTL configuration based on environment
    static func recommendedTTLConfiguration(for environment: AppEnvironment) -> TTLConfiguration {
        switch environment {
        case .development:
            // Shorter intervals for testing
            return TTLConfiguration(
                maxHeartbeatInterval: 120, // 2 minutes
                graceInterval: 30, // 30 seconds
                autoCheckoutEnabled: true
            )
            
        case .staging:
            // Standard intervals
            return TTLConfiguration(
                maxHeartbeatInterval: 300, // 5 minutes
                graceInterval: 60, // 1 minute
                autoCheckoutEnabled: true
            )
            
        case .production:
            // Conservative intervals for production
            return TTLConfiguration(
                maxHeartbeatInterval: 600, // 10 minutes
                graceInterval: 120, // 2 minutes
                autoCheckoutEnabled: true
            )
        }
    }
}

// MARK: - AppEnvironment (Should be defined elsewhere in your app)

public enum AppEnvironment {
    case development
    case staging
    case production
}