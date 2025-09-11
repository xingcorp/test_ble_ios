//
//  LogMonitor.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation

/// Protocol for external monitoring services (Crashlytics, Sentry, etc.)
public protocol LogMonitor {
    func recordEvent(_ event: String, parameters: [String: Any]?)
    func recordError(_ error: Error, parameters: [String: Any]?)
    func setUserId(_ userId: String?)
    func setCustomValue(_ value: Any?, forKey key: String)
}

/// Structured log entry for better analytics
public struct LogEntry: Codable {
    let timestamp: Date
    let level: String
    let category: String
    let message: String
    let file: String?
    let function: String?
    let line: Int?
    let metadata: [String: String]?
    
    public init(timestamp: Date = Date(),
                level: LogLevel,
                category: LogCategory,
                message: String,
                file: String? = nil,
                function: String? = nil,
                line: Int? = nil,
                metadata: [String: String]? = nil) {
        self.timestamp = timestamp
        self.level = String(describing: level)
        self.category = category.rawValue
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }
}

/// Extension to integrate monitoring with LoggerService
public extension LoggerService {
    
    private static var monitors: [LogMonitor] = []
    
    /// Add a monitoring service
    func addMonitor(_ monitor: LogMonitor) {
        Self.monitors.append(monitor)
    }
    
    /// Remove all monitors
    func clearMonitors() {
        Self.monitors.removeAll()
    }
    
    /// Internal method to notify monitors
    internal func notifyMonitors(level: LogLevel, message: String, category: LogCategory, error: Error? = nil) {
        let parameters: [String: Any] = [
            "level": String(describing: level),
            "category": category.rawValue,
            "message": message
        ]
        
        if level == .error || level == .fault {
            if let error = error {
                Self.monitors.forEach { $0.recordError(error, parameters: parameters) }
            } else {
                let customError = NSError(domain: "LoggerService", 
                                         code: level.rawValue, 
                                         userInfo: [NSLocalizedDescriptionKey: message])
                Self.monitors.forEach { $0.recordError(customError, parameters: parameters) }
            }
        } else {
            Self.monitors.forEach { $0.recordEvent(message, parameters: parameters) }
        }
    }
    
    /// Get structured logs for export
    func getStructuredLogs(since date: Date? = nil, 
                          category: LogCategory? = nil,
                          limit: Int = 1000) -> [LogEntry] {
        // This would read from the file logger and parse into structured format
        // For now, return empty - would need to enhance FileLogger
        return []
    }
    
    /// Export logs as JSON
    func exportLogsAsJSON(completion: @escaping (Result<URL, Error>) -> Void) {
        let logs = getStructuredLogs()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(logs)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                        in: .userDomainMask).first!
            let exportURL = documentsPath.appendingPathComponent("logs_export.json")
            try data.write(to: exportURL)
            
            completion(.success(exportURL))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Analytics helper for performance monitoring
public extension LoggerService {
    
    /// Track performance metrics
    func trackPerformance(operation: String, 
                         duration: TimeInterval,
                         success: Bool,
                         metadata: [String: Any]? = nil) {
        var params: [String: Any] = [
            "operation": operation,
            "duration_ms": Int(duration * 1000),
            "success": success
        ]
        
        if let metadata = metadata {
            metadata.forEach { params[$0.key] = $0.value }
        }
        
        Self.monitors.forEach { 
            $0.recordEvent("performance_metric", parameters: params) 
        }
        
        let emoji = success ? "✅" : "⚠️"
        info("\(emoji) Performance: \(operation) - \(String(format: "%.2f", duration))s", category: .app)
    }
    
    /// Track user actions
    func trackUserAction(_ action: String, 
                        parameters: [String: Any]? = nil) {
        Self.monitors.forEach { 
            $0.recordEvent("user_action_\(action)", parameters: parameters) 
        }
        
        info("👤 User Action: \(action)", category: .analytics)
    }
}
