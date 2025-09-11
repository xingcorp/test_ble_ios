//
//  EnhancedLogger.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import os.log

// MARK: - Log Level
public enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .verbose: return "📝"
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "🛑"
        case .critical: return "🔥"
        }
    }
}

// MARK: - Log Category
public enum LogCategory: String, CaseIterable {
    case general = "General"
    case beacon = "Beacon"
    case network = "Network"
    case session = "Session"
    case ui = "UI"
    case database = "Database"
    case performance = "Performance"
    case security = "Security"
}

// MARK: - Log Entry
public struct LogEntry: Codable {
    public let timestamp: Date
    public let level: String
    public let category: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: [String: String]?
    
    var formatted: String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timeStr = dateFormatter.string(from: timestamp)
        let metaStr = metadata?.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") ?? ""
        return "[\(timeStr)] [\(level)] [\(category)] \(message) | \(file):\(line) \(function) | \(metaStr)"
    }
}

// MARK: - Enhanced Logger
public final class EnhancedLogger {
    
    public static let shared = EnhancedLogger()
    
    private let subsystem = "com.attendance.beacon"
    private var loggers: [LogCategory: OSLog] = [:]
    private let fileLogger: FileLogger
    private var minLevel: LogLevel = .debug
    private let queue = DispatchQueue(label: "logger.queue", qos: .utility)
    
    private init() {
        self.fileLogger = FileLogger()
        
        // Initialize OS loggers for each category
        for category in LogCategory.allCases {
            loggers[category] = OSLog(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Configuration
    
    public func configure(minLevel: LogLevel) {
        self.minLevel = minLevel
    }
    
    // MARK: - Public Logging Methods
    
    public func verbose(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .verbose, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func debug(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func info(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func warning(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func error(
        _ message: String,
        category: LogCategory = .general,
        error: Error? = nil,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var enrichedMetadata = metadata ?? [:]
        if let error = error {
            enrichedMetadata["error_domain"] = (error as NSError).domain
            enrichedMetadata["error_code"] = String((error as NSError).code)
            enrichedMetadata["error_description"] = error.localizedDescription
        }
        log(level: .error, message: message, category: category, metadata: enrichedMetadata, file: file, function: function, line: line)
    }
    
    public func critical(
        _ message: String,
        category: LogCategory = .general,
        error: Error? = nil,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var enrichedMetadata = metadata ?? [:]
        if let error = error {
            enrichedMetadata["error_domain"] = (error as NSError).domain
            enrichedMetadata["error_code"] = String((error as NSError).code)
            enrichedMetadata["error_description"] = error.localizedDescription
        }
        log(level: .critical, message: message, category: category, metadata: enrichedMetadata, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging
    
    private func log(
        level: LogLevel,
        message: String,
        category: LogCategory,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minLevel else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        // Log to OS log
        if let osLog = loggers[category] {
            os_log("%{public}@", log: osLog, type: level.osLogType, message)
        }
        
        // Log to console in debug
        #if DEBUG
        let metaStr = metadata?.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") ?? ""
        print("\(level.emoji) [\(category.rawValue)] \(message) | \(fileName):\(line) | \(metaStr)")
        #endif
        
        // Log to file
        let entry = LogEntry(
            timestamp: Date(),
            level: String(describing: level),
            category: category.rawValue,
            message: message,
            file: fileName,
            function: function,
            line: line,
            metadata: metadata
        )
        
        queue.async {
            self.fileLogger.write(entry)
        }
    }
    
    // MARK: - Export & Management
    
    public func exportLogs() -> URL? {
        return fileLogger.exportLogs()
    }
    
    public func clearLogs() {
        fileLogger.clearLogs()
    }
    
    public func getLogFileSize() -> Int64 {
        return fileLogger.getFileSize()
    }
}

// MARK: - File Logger
private final class FileLogger {
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let maxFiles = 5
    private let logDirectory: URL
    private var currentLogFile: URL
    private let dateFormatter: DateFormatter
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logDirectory = documentsPath.appendingPathComponent("Logs", isDirectory: true)
        
        // Create logs directory
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        // Initialize current log file
        let fileName = "beacon_\(dateFormatter.string(from: Date())).log"
        currentLogFile = logDirectory.appendingPathComponent(fileName)
    }
    
    func write(_ entry: LogEntry) {
        // Check file size and rotate if needed
        if getFileSize() > maxFileSize {
            rotateLogFile()
        }
        
        // Write entry
        let line = entry.formatted + "\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: currentLogFile.path) {
                if let handle = try? FileHandle(forWritingTo: currentLogFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: currentLogFile)
            }
        }
    }
    
    func getFileSize() -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: currentLogFile.path)
        return attributes?[.size] as? Int64 ?? 0
    }
    
    private func rotateLogFile() {
        // Create new log file
        let fileName = "beacon_\(dateFormatter.string(from: Date())).log"
        currentLogFile = logDirectory.appendingPathComponent(fileName)
        
        // Clean old files if needed
        cleanOldLogs()
    }
    
    private func cleanOldLogs() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
            let logFiles = files.filter { $0.pathExtension == "log" }
            
            if logFiles.count > maxFiles {
                let sorted = logFiles.sorted { url1, url2 in
                    let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1! < date2!
                }
                
                let filesToDelete = sorted.prefix(logFiles.count - maxFiles)
                for file in filesToDelete {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to clean old logs: \(error)")
        }
    }
    
    func exportLogs() -> URL? {
        // Create zip or consolidated file
        let exportFile = logDirectory.appendingPathComponent("beacon_logs_export_\(Date().timeIntervalSince1970).txt")
        
        do {
            var allContent = ""
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
            
            for file in files.filter({ $0.pathExtension == "log" }).sorted(by: { $0.path < $1.path }) {
                if let content = try? String(contentsOf: file) {
                    allContent += "=== \(file.lastPathComponent) ===\n"
                    allContent += content
                    allContent += "\n\n"
                }
            }
            
            try allContent.write(to: exportFile, atomically: true, encoding: .utf8)
            return exportFile
        } catch {
            print("Failed to export logs: \(error)")
            return nil
        }
    }
    
    func clearLogs() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
            
            // Create new log file
            let fileName = "beacon_\(dateFormatter.string(from: Date())).log"
            currentLogFile = logDirectory.appendingPathComponent(fileName)
        } catch {
            print("Failed to clear logs: \(error)")
        }
    }
}

// MARK: - Backward Compatibility
// Maintain compatibility with existing Logger usage
public extension Logger {
    static func info(_ msg: String) {
        EnhancedLogger.shared.info(msg)
    }
    
    static func warn(_ msg: String) {
        EnhancedLogger.shared.warning(msg)
    }
    
    static func error(_ msg: String) {
        EnhancedLogger.shared.error(msg)
    }
}
