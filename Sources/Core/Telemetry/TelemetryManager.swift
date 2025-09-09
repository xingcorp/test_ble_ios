//
//  TelemetryManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import UIKit

/// Central telemetry manager for event tracking and metrics
public final class TelemetryManager {
    public static let shared = TelemetryManager()
    
    private let store: TelemetryStore
    private let performanceMonitor: PerformanceMonitor
    private var isEnabled = true
    
    private init() {
        self.store = FileTelemetryStore() ?? InMemoryTelemetryStore()
        self.performanceMonitor = PerformanceMonitor()
    }
    
    // MARK: - Public Methods
    
    public func configure(enabled: Bool) {
        self.isEnabled = enabled
    }
    
    public func track(
        _ type: EventType,
        severity: EventSeverity = .info,
        sessionId: String? = nil,
        siteId: String? = nil,
        metadata: [String: String] = [:],
        metrics: [String: Double]? = nil
    ) {
        guard isEnabled else { return }
        
        var enrichedMetadata = metadata
        enrichedMetadata["device_model"] = UIDevice.current.model
        enrichedMetadata["os_version"] = UIDevice.current.systemVersion
        enrichedMetadata["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        
        var enrichedMetrics = metrics ?? [:]
        enrichedMetrics[MetricKey.batteryLevel] = Double(UIDevice.current.batteryLevel)
        enrichedMetrics[MetricKey.memoryUsage] = performanceMonitor.currentMemoryUsage()
        
        let event = TelemetryEvent(
            type: type,
            severity: severity,
            sessionId: sessionId,
            siteId: siteId,
            metadata: enrichedMetadata,
            metrics: enrichedMetrics
        )
        
        store.record(event)
        
        // Also log to console in debug
        #if DEBUG
        logToConsole(event)
        #endif
    }
    
    public func trackError(_ error: Error, context: String? = nil) {
        track(
            .error,
            severity: .error,
            metadata: [
                "error_domain": (error as NSError).domain,
                "error_code": String((error as NSError).code),
                "error_description": error.localizedDescription,
                "context": context ?? "unknown"
            ]
        )
    }
    
    public func exportLogs() -> URL? {
        return store.export()
    }
    
    public func clearLogs() {
        store.clear()
    }
    
    // MARK: - Private Methods
    
    private func logToConsole(_ event: TelemetryEvent) {
        let emoji: String
        switch event.severity {
        case .verbose: emoji = "📝"
        case .info: emoji = "ℹ️"
        case .warning: emoji = "⚠️"
        case .error: emoji = "🛑"
        case .critical: emoji = "🔥"
        }
        
        print("\(emoji) [\(event.type.rawValue)] \(event.metadata)")
    }
}

// MARK: - In-Memory Store (Fallback)

private final class InMemoryTelemetryStore: TelemetryStore {
    private var events: [TelemetryEvent] = []
    private let queue = DispatchQueue(label: "telemetry.memory.queue")
    
    func record(_ event: TelemetryEvent) {
        queue.async {
            self.events.append(event)
            // Keep only last 1000 events in memory
            if self.events.count > 1000 {
                self.events.removeFirst(self.events.count - 1000)
            }
        }
    }
    
    func export() -> URL? {
        return nil // Memory store cannot export
    }
    
    func clear() {
        queue.async {
            self.events.removeAll()
        }
    }
}

// MARK: - Performance Monitor

private final class PerformanceMonitor {
    func currentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0
    }
}
