//
//  LoggerService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import OSLog
import os

/// Log levels matching OSLog types for consistency
public enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fault: return "🔥"
        }
    }
}

/// Categories for organizing logs
public enum LogCategory: String, CaseIterable {
    case app = "App"
    case beacon = "Beacon"
    case network = "Network"
    case storage = "Storage"
    case ui = "UI"
    case background = "Background"
    case notification = "Notification"
    case location = "Location"
    case analytics = "Analytics"
    case security = "Security"
}

/// Protocol for log exporters
public protocol LogExporter {
    func export(completion: @escaping (Result<URL, Error>) -> Void)
    func clear()
}

/// Main logger service using OSLog with privacy-first approach
public final class LoggerService {
    
    // MARK: - Singleton
    public static let shared = LoggerService()
    
    // MARK: - Properties
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.oxii.beacon"
    @available(iOS 14.0, *)
    private var loggers: [LogCategory: os.Logger] = [:]
    private let fileLogger: FileLogger
    private let logQueue = DispatchQueue(label: "com.oxii.logger", qos: .utility)
    
    // Configuration
    public var minimumLevel: LogLevel = .debug
    public var isFileLoggingEnabled = true
    public var isConsoleLoggingEnabled = true
    
    // MARK: - Initialization
    private init() {
        self.fileLogger = FileLogger()
        setupLoggers()
    }
    
    private func setupLoggers() {
        for category in LogCategory.allCases {
            if #available(iOS 14.0, *) {
                loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
            }
        }
    }
    
    // MARK: - Public Logging Methods
    
    public func debug(_ message: String, 
                     category: LogCategory = .app,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    public func info(_ message: String,
                    category: LogCategory = .app,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String,
                       category: LogCategory = .app,
                       file: String = #file,
                       function: String = #function,
                       line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    public func error(_ message: String,
                     error: Error? = nil,
                     category: LogCategory = .app,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        let fullMessage = error != nil ? "\(message) - Error: \(error!.localizedDescription)" : message
        log(fullMessage, level: .error, category: category, file: file, function: function, line: line)
    }
    
    public func fault(_ message: String,
                     category: LogCategory = .app,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging
    
    private func log(_ message: String,
                    level: LogLevel,
                    category: LogCategory,
                    file: String,
                    function: String,
                    line: Int) {
        
        guard level.rawValue >= minimumLevel.rawValue else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        // OSLog - System logging
        if #available(iOS 14.0, *) {
            if let logger = loggers[category] {
                switch level {
                case .debug:
                    logger.debug("\(logMessage)")
                case .info:
                    logger.info("\(logMessage)")
                case .warning:
                    logger.notice("\(logMessage)")
                case .error:
                    logger.error("\(logMessage)")
                case .fault:
                    logger.critical("\(logMessage)")
                }
            }
        } else {
            // Fallback for iOS 13
            os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category.rawValue), type: level.osLogType, logMessage)
        }
        
        // File logging
        if isFileLoggingEnabled {
            logQueue.async { [weak self] in
                self?.fileLogger.log(message: logMessage, level: level, category: category)
            }
        }
        
        // Console logging for debug - only if explicitly enabled
        #if DEBUG
        if isConsoleLoggingEnabled && ProcessInfo.processInfo.environment["ENABLE_CONSOLE_LOG"] == "1" {
            print("\(level.emoji) [\(category.rawValue)] \(logMessage)")
        }
        #endif
    }
    
    // MARK: - Log Export
    
    public func exportLogs(completion: @escaping (Result<URL, Error>) -> Void) {
        fileLogger.export(completion: completion)
    }
    
    public func clearLogs() {
        fileLogger.clear()
    }
    
    // MARK: - App Lifecycle Logging
    
    public func logAppLifecycle(_ message: String, category: LogCategory = .app) {
        info("[LIFECYCLE] \(message)", category: category)
    }
    
    // MARK: - Performance Logging
    
    public func measureTime<T>(
        operation: String,
        category: LogCategory = .app,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            info("⏱ \(operation) completed in \(String(format: "%.3f", timeElapsed))s", category: category)
        }
        return try block()
    }
}

// MARK: - File Logger

private final class FileLogger: LogExporter {
    
    private let fileName = "beacon_attendance_logs.txt"
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10MB
    private var fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    
    private var logFileURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                          in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent(fileName)
    }
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        setupFileHandle()
    }
    
    private func setupFileHandle() {
        guard let url = logFileURL else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        
        fileHandle = try? FileHandle(forWritingTo: url)
        fileHandle?.seekToEndOfFile()
    }
    
    func log(message: String, level: LogLevel, category: LogCategory) {
        guard let fileHandle = fileHandle else {
            setupFileHandle()
            return
        }
        
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "\(timestamp) [\(level)] [\(category.rawValue)] \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            fileHandle.write(data)
            
            // Check file size and rotate if needed
            if let fileSize = try? fileHandle.offset(), fileSize > maxFileSize {
                rotateLogFile()
            }
        }
    }
    
    private func rotateLogFile() {
        fileHandle?.closeFile()
        
        guard let url = logFileURL else { return }
        let backupURL = url.deletingPathExtension().appendingPathExtension("old.txt")
        
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.moveItem(at: url, to: backupURL)
        
        setupFileHandle()
    }
    
    func export(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = logFileURL else {
            completion(.failure(NSError(domain: "LoggerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage error"])))
            return
        }
        
        fileHandle?.synchronizeFile()
        
        // Create a copy for export
        let exportURL = url.deletingPathExtension()
            .appendingPathExtension("export")
            .appendingPathExtension("txt")
        
        do {
            try? FileManager.default.removeItem(at: exportURL)
            try FileManager.default.copyItem(at: url, to: exportURL)
            completion(.success(exportURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    func clear() {
        fileHandle?.closeFile()
        if let url = logFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        setupFileHandle()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
}

// MARK: - Convenience Extensions

public extension LoggerService {
    
    /// Log a network request
    func logNetworkRequest(_ request: URLRequest, category: LogCategory = .network) {
        info("🌐 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")", 
             category: category)
    }
    
    /// Log a network response
    func logNetworkResponse(_ response: URLResponse?, data: Data?, error: Error?, category: LogCategory = .network) {
        if let error = error {
            self.error("🌐 Network error", error: error, category: category)
        } else if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = (200..<300).contains(httpResponse.statusCode) ? "✅" : "⚠️"
            info("\(statusEmoji) Response: \(httpResponse.statusCode) - \(data?.count ?? 0) bytes", 
                 category: category)
        }
    }
    
    /// Log app lifecycle events
    func logAppLifecycle(_ event: String) {
        info("📱 \(event)", category: .app)
    }
    
    /// Log beacon events
    func logBeaconEvent(_ event: String, beaconId: String? = nil) {
        let message = beaconId != nil ? "\(event) - Beacon: \(beaconId!)" : event
        info("📡 \(message)", category: .beacon)
    }
}
