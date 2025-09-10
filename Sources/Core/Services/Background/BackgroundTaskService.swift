//
//  BackgroundTaskService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
#if os(iOS)
import BackgroundTasks
#endif

/// Service for managing background tasks
public final class BackgroundTaskService {
    
    // MARK: - Singleton
    public static let shared = BackgroundTaskService()
    
    // MARK: - Constants
    private let beaconSyncTaskId = "com.oxii.beacon.sync"
    private let dataSyncTaskId = "com.oxii.beacon.datasync"
    private let cleanupTaskId = "com.oxii.beacon.cleanup"
    
    // MARK: - Properties
    private var isRegistered = false
    private let queue = DispatchQueue(label: "com.oxii.backgroundtask", qos: .background)
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Register background tasks
    public func registerTasks() {
        guard !isRegistered else { 
            LoggerService.shared.warning("Background tasks already registered")
            return 
        }
        
        #if os(iOS)
        // Register beacon sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: beaconSyncTaskId,
            using: queue
        ) { [weak self] task in
            self?.handleBeaconSync(task: task as! BGAppRefreshTask)
        }
        
        // Register data sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: dataSyncTaskId,
            using: queue
        ) { [weak self] task in
            self?.handleDataSync(task: task as! BGProcessingTask)
        }
        
        // Register cleanup task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: cleanupTaskId,
            using: queue
        ) { [weak self] task in
            self?.handleCleanup(task: task as! BGProcessingTask)
        }
        
        isRegistered = true
        LoggerService.shared.info("✅ Background tasks registered successfully")
        
        // Schedule initial tasks
        scheduleBeaconSync()
        scheduleDataSync()
        scheduleCleanup()
        #else
        LoggerService.shared.warning("Background tasks not available on this platform")
        isRegistered = true
        #endif
    }
    
    /// Schedule beacon sync task
    public func scheduleBeaconSync() {
        #if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: beaconSyncTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            LoggerService.shared.debug("Beacon sync task scheduled")
        } catch {
            LoggerService.shared.error("Failed to schedule beacon sync: \(error.localizedDescription)")
        }
        #else
        LoggerService.shared.debug("Background tasks not available - skipping beacon sync")
        #endif
    }
    
    /// Schedule data sync task
    public func scheduleDataSync() {
        #if os(iOS)
        let request = BGProcessingTaskRequest(identifier: dataSyncTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            LoggerService.shared.debug("Data sync task scheduled")
        } catch {
            LoggerService.shared.error("Failed to schedule data sync: \(error.localizedDescription)")
        }
        #else
        LoggerService.shared.debug("Background tasks not available - skipping data sync")
        #endif
    }
    
    /// Schedule cleanup task
    public func scheduleCleanup() {
        #if os(iOS)
        let request = BGProcessingTaskRequest(identifier: cleanupTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            LoggerService.shared.debug("Cleanup task scheduled")
        } catch {
            LoggerService.shared.error("Failed to schedule cleanup: \(error.localizedDescription)")
        }
        #else
        LoggerService.shared.debug("Background tasks not available - skipping cleanup")
        #endif
    }
    
    // MARK: - Task Handlers
    
    #if os(iOS)
    private func handleBeaconSync(task: BGAppRefreshTask) {
        LoggerService.shared.info("Starting beacon sync background task")
        
        task.expirationHandler = {
            LoggerService.shared.warning("Beacon sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform beacon sync
        queue.async {
            // TODO: Implement actual beacon sync logic
            LoggerService.shared.info("Beacon sync completed")
            task.setTaskCompleted(success: true)
            
            // Schedule next sync
            self.scheduleBeaconSync()
        }
    }
    
    private func handleDataSync(task: BGProcessingTask) {
        LoggerService.shared.info("Starting data sync background task")
        
        task.expirationHandler = {
            LoggerService.shared.warning("Data sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform data sync
        queue.async {
            // TODO: Implement actual data sync logic
            LoggerService.shared.info("Data sync completed")
            task.setTaskCompleted(success: true)
            
            // Schedule next sync
            self.scheduleDataSync()
        }
    }
    
    private func handleCleanup(task: BGProcessingTask) {
        LoggerService.shared.info("Starting cleanup background task")
        
        task.expirationHandler = {
            LoggerService.shared.warning("Cleanup task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform cleanup
        queue.async {
            // Clear old logs
            LoggerService.shared.clearLogs()
            
            // TODO: Clear old attendance records, cache, etc.
            
            LoggerService.shared.info("Cleanup completed")
            task.setTaskCompleted(success: true)
            
            // Schedule next cleanup
            self.scheduleCleanup()
        }
    }
    #endif
    
    /// Cancel all pending tasks
    public func cancelAllTasks() {
        #if os(iOS)
        BGTaskScheduler.shared.cancelAllTaskRequests()
        LoggerService.shared.info("All background tasks cancelled")
        #else
        LoggerService.shared.debug("Background tasks not available - nothing to cancel")
        #endif
    }
    
    /// Get pending task requests (for debugging)
    #if os(iOS)
    public func getPendingTasks(completion: @escaping ([BGTaskRequest]) -> Void) {
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            completion(requests)
        }
    }
    #else
    public func getPendingTasks(completion: @escaping ([Any]) -> Void) {
        completion([]) // Return empty array on platforms without BackgroundTasks
    }
    #endif
}
