//
//  HeartbeatService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import BackgroundTasks

public protocol HeartbeatServiceDelegate: AnyObject {
    func heartbeatServiceDidTrigger()
}

/// Manages periodic heartbeat with smart scheduling
public final class HeartbeatService {
    
    // Configuration
    public struct Configuration {
        let minInterval: TimeInterval
        let maxInterval: TimeInterval
        let useBackgroundTask: Bool
        
        public static let `default` = Configuration(
            minInterval: 60,      // 1 minute when active
            maxInterval: 300,     // 5 minutes when idle
            useBackgroundTask: true
        )
        
        public static let aggressive = Configuration(
            minInterval: 30,      // 30 seconds
            maxInterval: 120,     // 2 minutes
            useBackgroundTask: true
        )
    }
    
    // State
    private var timer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var lastHeartbeatTime: Date?
    private var isActive = false
    private let configuration: Configuration
    
    public weak var delegate: HeartbeatServiceDelegate?
    
    private let taskIdentifier = AppConstants.BackgroundTask.heartbeatIdentifier
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        registerBackgroundTask()
    }
    
    // MARK: - Public Methods
    
    public func start() {
        guard !isActive else { return }
        
        isActive = true
        Logger.info("HeartbeatService started")
        TelemetryManager.shared.track(.heartbeat, metadata: ["action": "start"])
        
        scheduleNextHeartbeat(interval: configuration.minInterval)
        
        if configuration.useBackgroundTask {
            scheduleBackgroundHeartbeat()
        }
    }
    
    public func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
        
        Logger.info("HeartbeatService stopped")
        TelemetryManager.shared.track(.heartbeat, metadata: ["action": "stop"])
    }
    
    public func triggerImmediateHeartbeat() {
        guard isActive else { return }
        performHeartbeat()
    }
    
    // MARK: - Private Methods
    
    private func performHeartbeat() {
        lastHeartbeatTime = Date()
        
        Logger.info("💓 Heartbeat triggered")
        delegate?.heartbeatServiceDidTrigger()
        
        TelemetryManager.shared.track(
            .heartbeat,
            metadata: ["trigger": "scheduled"],
            metrics: [
                "interval_seconds": lastHeartbeatTime.map { Date().timeIntervalSince($0) } ?? 0
            ]
        )
        
        // Schedule next based on activity
        let nextInterval = calculateNextInterval()
        scheduleNextHeartbeat(interval: nextInterval)
    }
    
    private func calculateNextInterval() -> TimeInterval {
        // In production, this could be based on:
        // - User activity level
        // - Time of day
        // - Battery level
        // - Network conditions
        
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel > 0 && batteryLevel < AppConstants.Battery.lowThreshold {
            // Low battery - use max interval
            return configuration.maxInterval
        }
        
        // For now, use min interval when active
        return configuration.minInterval
    }
    
    private func scheduleNextHeartbeat(interval: TimeInterval) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.performHeartbeat()
        }
    }
    
    // MARK: - Background Task
    
    private func registerBackgroundTask() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskIdentifier,
                using: nil
            ) { [weak self] task in
                self?.handleBackgroundTask(task as! BGAppRefreshTask)
            }
        }
    }
    
    private func scheduleBackgroundHeartbeat() {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: configuration.maxInterval)
            
            do {
                try BGTaskScheduler.shared.submit(request)
                Logger.info("Background heartbeat scheduled")
            } catch {
                Logger.error("Failed to schedule background heartbeat: \(error)")
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            Logger.warn("Background heartbeat task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform heartbeat
        if isActive {
            performHeartbeat()
        }
        
        // Schedule next
        scheduleBackgroundHeartbeat()
        
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - App Lifecycle
    
    public func handleAppDidEnterBackground() {
        guard isActive else { return }
        
        // Request background time to complete heartbeat
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stop()
        }
        
        // Schedule background refresh
        if configuration.useBackgroundTask {
            scheduleBackgroundHeartbeat()
        }
    }
    
    public func handleAppWillEnterForeground() {
        guard isActive else { return }
        
        // Check if we need immediate heartbeat
        if let lastTime = lastHeartbeatTime,
           Date().timeIntervalSince(lastTime) > configuration.maxInterval {
            triggerImmediateHeartbeat()
        }
    }
}
