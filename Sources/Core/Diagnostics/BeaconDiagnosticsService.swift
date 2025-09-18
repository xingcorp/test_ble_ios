//
//  BeaconDiagnosticsService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Enterprise-grade beacon diagnostics service with SOLID principles
//

import Foundation
import CoreLocation
import CoreBluetooth

// MARK: - Protocols (Dependency Inversion Principle)

public protocol BeaconDiagnosticsServiceProtocol: AnyObject {
    var delegate: BeaconDiagnosticsDelegate? { get set }
    
    /// Start diagnostic monitoring
    func startDiagnostics()
    
    /// Stop diagnostic monitoring
    func stopDiagnostics()
    
    /// Perform comprehensive system health check
    func performSystemHealthCheck() async -> SystemHealthReport
    
    /// Report a diagnostic issue
    func reportIssue(_ issue: DiagnosticIssue)
    
    /// Get current diagnostic status
    func getCurrentStatus() -> DiagnosticStatus
    
    /// Export diagnostic logs
    func exportDiagnosticLogs() async -> URL?
}

public protocol BeaconDiagnosticsDelegate: AnyObject {
    func diagnosticsDidDetectIssue(_ issue: DiagnosticIssue)
    func diagnosticsDidUpdateStatus(_ status: DiagnosticStatus)
    func diagnosticsDidCompleteHealthCheck(_ report: SystemHealthReport)
}

// MARK: - Diagnostic Status

public enum DiagnosticStatus {
    case idle
    case monitoring
    case performingHealthCheck
    case error(Error)
    
    public var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .monitoring: return "Monitoring"
        case .performingHealthCheck: return "Health Check"
        case .error: return "Error"
        }
    }
    
    public var emoji: String {
        switch self {
        case .idle: return "⚪"
        case .monitoring: return "🟢"
        case .performingHealthCheck: return "🔍"
        case .error: return "🔴"
        }
    }
}

// MARK: - Main Diagnostics Service

/// Enterprise-grade beacon diagnostics service
/// Follows Single Responsibility Principle - coordinates diagnostic activities
public final class BeaconDiagnosticsService: BeaconDiagnosticsServiceProtocol {
    
    // MARK: - Singleton
    public static let shared = BeaconDiagnosticsService()
    
    // MARK: - Dependencies (Dependency Injection)
    private let systemHealthMonitor: SystemHealthMonitorProtocol
    private let issueCollector: DiagnosticIssueCollector
    private let reportGenerator: DiagnosticReportGenerator
    private let logger: LoggerServiceProtocol
    
    // MARK: - Properties
    public weak var delegate: BeaconDiagnosticsDelegate?
    
    private var currentStatus: DiagnosticStatus = .idle {
        didSet {
            delegate?.diagnosticsDidUpdateStatus(currentStatus)
        }
    }
    
    private var isMonitoring = false
    private let diagnosticsQueue = DispatchQueue(label: "com.beacon.diagnostics", qos: .utility)
    
    // MARK: - Initialization (Dependency Injection)
    
    public init(
        systemHealthMonitor: SystemHealthMonitorProtocol = SystemHealthMonitor(),
        issueCollector: DiagnosticIssueCollector = DiagnosticIssueCollector(),
        reportGenerator: DiagnosticReportGenerator = DiagnosticReportGenerator(),
        logger: LoggerServiceProtocol = LoggerService.shared
    ) {
        self.systemHealthMonitor = systemHealthMonitor
        self.issueCollector = issueCollector
        self.reportGenerator = reportGenerator
        self.logger = logger
        
        // Setup monitoring delegates
        systemHealthMonitor.delegate = self
        issueCollector.delegate = self
        
        logger.info("✅ BeaconDiagnosticsService initialized", category: .beacon)
    }
    
    // MARK: - Public Interface
    
    public func startDiagnostics() {
        guard !isMonitoring else {
            logger.warning("Diagnostics already monitoring", category: .beacon)
            return
        }
        
        diagnosticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.logger.info("🔍 Starting beacon diagnostics monitoring", category: .beacon)
            
            DispatchQueue.main.async {
                self.currentStatus = .monitoring
                self.isMonitoring = true
            }
            
            // Start system health monitoring
            self.systemHealthMonitor.startMonitoring()
            
            // Start collecting diagnostic issues
            self.issueCollector.startCollecting()
            
            self.logger.info("✅ Beacon diagnostics monitoring started", category: .beacon)
        }
    }
    
    public func stopDiagnostics() {
        guard isMonitoring else {
            logger.warning("Diagnostics not monitoring", category: .beacon)
            return
        }
        
        diagnosticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.logger.info("🛑 Stopping beacon diagnostics monitoring", category: .beacon)
            
            self.systemHealthMonitor.stopMonitoring()
            self.issueCollector.stopCollecting()
            
            DispatchQueue.main.async {
                self.currentStatus = .idle
                self.isMonitoring = false
            }
            
            self.logger.info("✅ Beacon diagnostics monitoring stopped", category: .beacon)
        }
    }
    
    public func performSystemHealthCheck() async -> SystemHealthReport {
        logger.info("🔍 Performing comprehensive system health check", category: .beacon)
        
        await MainActor.run {
            currentStatus = .performingHealthCheck
        }
        
        let report = await withTaskGroup(of: Void.self) { group in
            var bluetoothStatus: BluetoothStatus?
            var permissionStatus: PermissionStatus?
            var batteryMetrics: BatteryImpactMetrics?
            var backgroundStatus: BackgroundExecutionStatus?
            var beaconStatus: BeaconMonitoringStatus?
            
            // Parallel health checks for efficiency
            group.addTask { [weak self] in
                bluetoothStatus = await self?.systemHealthMonitor.checkBluetoothStatus()
            }
            
            group.addTask { [weak self] in
                permissionStatus = await self?.systemHealthMonitor.checkPermissionStatus()
            }
            
            group.addTask { [weak self] in
                batteryMetrics = await self?.systemHealthMonitor.checkBatteryImpact()
            }
            
            group.addTask { [weak self] in
                backgroundStatus = await self?.systemHealthMonitor.checkBackgroundStatus()
            }
            
            group.addTask { [weak self] in
                beaconStatus = await self?.systemHealthMonitor.checkBeaconMonitoringStatus()
            }
            
            await group.waitForAll()
            
            // Generate comprehensive report
            return reportGenerator.generateSystemHealthReport(
                bluetoothStatus: bluetoothStatus ?? BluetoothStatus(isAvailable: false, state: .unknown),
                permissionStatus: permissionStatus ?? PermissionStatus(locationAuth: .notDetermined),
                batteryMetrics: batteryMetrics ?? BatteryImpactMetrics(),
                backgroundStatus: backgroundStatus ?? BackgroundExecutionStatus(refreshEnabled: false),
                beaconStatus: beaconStatus ?? BeaconMonitoringStatus(monitored: 0),
                systemInfo: SystemInfo(),
                issues: issueCollector.getAllIssues()
            )
        }
        
        await MainActor.run {
            currentStatus = isMonitoring ? .monitoring : .idle
        }
        
        logger.info("✅ System health check completed", category: .beacon)
        delegate?.diagnosticsDidCompleteHealthCheck(report)
        
        return report
    }
    
    public func reportIssue(_ issue: DiagnosticIssue) {
        logger.info("📝 Diagnostic issue reported: \(issue.title)", category: .beacon)
        
        issueCollector.addIssue(issue)
        delegate?.diagnosticsDidDetectIssue(issue)
    }
    
    public func getCurrentStatus() -> DiagnosticStatus {
        return currentStatus
    }
    
    public func exportDiagnosticLogs() async -> URL? {
        logger.info("📤 Exporting diagnostic logs", category: .beacon)
        
        do {
            // Get comprehensive system report
            let healthReport = await performSystemHealthCheck()
            
            // Generate diagnostic report
            let diagnosticData = DiagnosticExportData(
                timestamp: Date(),
                systemHealthReport: healthReport,
                allIssues: issueCollector.getAllIssues(),
                logEntries: await logger.getRecentLogs(category: .beacon)
            )
            
            // Export to file
            let fileURL = try await exportToFile(diagnosticData)
            
            logger.info("✅ Diagnostic logs exported to: \(fileURL.path)", category: .beacon)
            return fileURL
            
        } catch {
            logger.error("Failed to export diagnostic logs", error: error, category: .beacon)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func exportToFile(_ data: DiagnosticExportData) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        
        let fileName = "beacon-diagnostics-\(DateFormatter.fileNameFormatter.string(from: Date())).json"
        let documentsPath = FileManager.default.documentsDirectory
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        return fileURL
    }
}

// MARK: - SystemHealthMonitorDelegate

extension BeaconDiagnosticsService: SystemHealthMonitorDelegate {
    public func systemHealthMonitor(_ monitor: SystemHealthMonitorProtocol, didDetectIssue issue: DiagnosticIssue) {
        reportIssue(issue)
    }
    
    public func systemHealthMonitor(_ monitor: SystemHealthMonitorProtocol, didUpdateHealthStatus status: HealthScore) {
        logger.debug("System health status updated: \(status.rawValue)", category: .beacon)
    }
}

// MARK: - DiagnosticIssueCollectorDelegate

extension BeaconDiagnosticsService: DiagnosticIssueCollectorDelegate {
    public func issueCollector(_ collector: DiagnosticIssueCollector, didCollectIssue issue: DiagnosticIssue) {
        delegate?.diagnosticsDidDetectIssue(issue)
    }
}

// MARK: - Export Data Model

private struct DiagnosticExportData: Codable {
    let timestamp: Date
    let systemHealthReport: SystemHealthReport
    let allIssues: [DiagnosticIssue]
    let logEntries: [LogEntry]
}

private struct LogEntry: Codable {
    let timestamp: Date
    let level: String
    let category: String
    let message: String
}

// MARK: - Helper Extensions

private extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()
}

private extension FileManager {
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// MARK: - Placeholder Protocols (will be implemented in separate files)

public protocol SystemHealthMonitorProtocol: AnyObject {
    var delegate: SystemHealthMonitorDelegate? { get set }
    func startMonitoring()
    func stopMonitoring()
    func checkBluetoothStatus() async -> BluetoothStatus
    func checkPermissionStatus() async -> PermissionStatus
    func checkBatteryImpact() async -> BatteryImpactMetrics
    func checkBackgroundStatus() async -> BackgroundExecutionStatus
    func checkBeaconMonitoringStatus() async -> BeaconMonitoringStatus
}

public protocol SystemHealthMonitorDelegate: AnyObject {
    func systemHealthMonitor(_ monitor: SystemHealthMonitorProtocol, didDetectIssue issue: DiagnosticIssue)
    func systemHealthMonitor(_ monitor: SystemHealthMonitorProtocol, didUpdateHealthStatus status: HealthScore)
}

public protocol DiagnosticIssueCollectorDelegate: AnyObject {
    func issueCollector(_ collector: DiagnosticIssueCollector, didCollectIssue issue: DiagnosticIssue)
}

// These will be implemented in separate files for clean architecture
public final class DiagnosticIssueCollector {
    public weak var delegate: DiagnosticIssueCollectorDelegate?
    private var issues: [DiagnosticIssue] = []
    
    public func startCollecting() { /* Implementation */ }
    public func stopCollecting() { /* Implementation */ }
    public func addIssue(_ issue: DiagnosticIssue) { 
        issues.append(issue)
        delegate?.issueCollector(self, didCollectIssue: issue)
    }
    public func getAllIssues() -> [DiagnosticIssue] { return issues }
}

public final class DiagnosticReportGenerator {
    public func generateSystemHealthReport(
        bluetoothStatus: BluetoothStatus,
        permissionStatus: PermissionStatus,
        batteryMetrics: BatteryImpactMetrics,
        backgroundStatus: BackgroundExecutionStatus,
        beaconStatus: BeaconMonitoringStatus,
        systemInfo: SystemInfo,
        issues: [DiagnosticIssue]
    ) -> SystemHealthReport {
        
        // Calculate overall health score based on component scores
        let healthScore = calculateOverallHealth(
            bluetooth: bluetoothStatus,
            permissions: permissionStatus,
            battery: batteryMetrics,
            background: backgroundStatus,
            beacon: beaconStatus
        )
        
        return SystemHealthReport(
            overallHealth: healthScore,
            bluetoothStatus: bluetoothStatus,
            permissionStatus: permissionStatus,
            batteryImpact: batteryMetrics,
            backgroundStatus: backgroundStatus,
            beaconMonitoringStatus: beaconStatus,
            systemInfo: systemInfo,
            issues: issues
        )
    }
    
    private func calculateOverallHealth(
        bluetooth: BluetoothStatus,
        permissions: PermissionStatus,
        battery: BatteryImpactMetrics,
        background: BackgroundExecutionStatus,
        beacon: BeaconMonitoringStatus
    ) -> HealthScore {
        var score = 0
        var maxScore = 0
        
        // Bluetooth health (25 points)
        maxScore += 25
        if bluetooth.isAvailable {
            score += 25
        }
        
        // Permission health (30 points)
        maxScore += 30
        if permissions.isOptimalConfiguration {
            score += 30
        } else if permissions.locationAuthorization.contains("When In Use") {
            score += 15
        }
        
        // Battery health (15 points)
        maxScore += 15
        if battery.estimatedImpactPercentage < 1.0 {
            score += 15
        } else if battery.estimatedImpactPercentage < 5.0 {
            score += 10
        }
        
        // Background execution health (15 points)
        maxScore += 15
        if background.backgroundAppRefreshEnabled {
            score += 15
        }
        
        // Beacon monitoring health (15 points)
        maxScore += 15
        if beacon.regionsActive > 0 && beacon.monitoringErrors.isEmpty {
            score += 15
        } else if beacon.regionsMonitored > 0 {
            score += 8
        }
        
        let percentage = Double(score) / Double(maxScore) * 100
        
        switch percentage {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        default: return .poor
        }
    }
}

// Extension to LoggerServiceProtocol for diagnostic logging
extension LoggerServiceProtocol {
    func getRecentLogs(category: LogCategory) async -> [LogEntry] {
        // This would be implemented to return recent logs
        // For now, return empty array as placeholder
        return []
    }
}