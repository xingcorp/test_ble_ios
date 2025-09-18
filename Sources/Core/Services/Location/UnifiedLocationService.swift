//
//  UnifiedLocationService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Purpose: Single consolidated CLLocationManager instance for entire app
//

import Foundation
import CoreLocation
import os.log

/// Delegate protocol for location updates
public protocol UnifiedLocationDelegate: AnyObject {
    func unifiedLocationService(_ service: UnifiedLocationService, didUpdateLocations locations: [CLLocation])
    func unifiedLocationService(_ service: UnifiedLocationService, didFailWithError error: Error)
    func unifiedLocationService(_ service: UnifiedLocationService, didChangeAuthorization status: CLAuthorizationStatus)
}

/// Delegate protocol for beacon operations
public protocol UnifiedBeaconDelegate: AnyObject {
    func unifiedLocationService(_ service: UnifiedLocationService, didEnterRegion region: CLBeaconRegion)
    func unifiedLocationService(_ service: UnifiedLocationService, didExitRegion region: CLBeaconRegion)
    func unifiedLocationService(_ service: UnifiedLocationService, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
    func unifiedLocationService(_ service: UnifiedLocationService, didDetermineState state: CLRegionState, for region: CLBeaconRegion)
}

/// The single source of truth for all location and beacon operations
/// This service consolidates all CLLocationManager usage to prevent conflicts and optimize battery
/// Conforms to UnifiedLocationProvider protocol for clean architecture
public final class UnifiedLocationService: NSObject, UnifiedLocationProvider {
    
    // MARK: - Singleton
    public static let shared = UnifiedLocationService()
    
// MARK: - Properties
    
    /// The single CLLocationManager instance for the entire app
    private let locationManager: CLLocationManager
    
    /// Thread-safe delegate management
    private let delegateQueue = DispatchQueue(label: "com.oxii.location.delegates", attributes: .concurrent)
    
    /// Weak references to location delegates
    private var locationDelegates = NSHashTable<AnyObject>.weakObjects()
    
    /// Weak references to beacon delegates  
    private var beaconDelegates = NSHashTable<AnyObject>.weakObjects()
    
    /// Track monitored regions
    private var monitoredBeaconRegions: [String: CLBeaconRegion] = [:]
    
    /// Track ranged regions
    private var rangedBeaconRegions: [String: CLBeaconRegion] = [:]
    
    /// Location update continuations for async/await
    private var locationContinuations: [UUID: CheckedContinuation<CLLocation, Error>] = [:]
    
    /// Debounce mechanism for location requests
    private var locationRequestDebounceTimer: Timer?
    private var pendingLocationRequestId: UUID?
    private var pendingLocationContinuation: CheckedContinuation<CLLocation, Error>?
    private let debounceWindow: TimeInterval = 2.0 // 2 seconds debounce window
    private let debounceQueue = DispatchQueue(label: "com.oxii.location.debounce", qos: .userInitiated)
    
    /// Burst mode timers and state
    private var burstModeTimer: Timer?
    private var isBurstModeActive = false
    private var requestedBurstLocation = false
    private let burstModeInterval: TimeInterval = 5.0 // 5 seconds between bursts
    private let burstModeDuration: TimeInterval = 2.0 // 2 seconds active scanning per burst
    
    /// Task cancellation support
    private var locationTasks: [UUID: Task<Void, Never>] = [:]
    private var cancellables: [UUID: Bool] = [:]
    private let taskQueue = DispatchQueue(label: "com.oxii.location.tasks", attributes: .concurrent)
    
    /// Performance monitoring and battery tracking
    private var operationStartTimes: [String: Date] = [:]
    private var batteryImpactScore: Double = 0.0
    private let performanceQueue = DispatchQueue(label: "com.oxii.location.performance", qos: .utility)
    
    /// Battery optimization telemetry
    private var batteryTelemetry = BatteryOptimizationTelemetry()
    private var lastTelemetryReport: Date = Date()
    private let telemetryReportInterval: TimeInterval = 300 // 5 minutes
    
    /// State management queue for thread-safe operations
    private let stateQueue = DispatchQueue(label: "com.oxii.location.state", qos: .userInitiated)
    
    // MARK: - Configuration
    
    public var desiredAccuracy: CLLocationAccuracy {
        get { locationManager.desiredAccuracy }
        set { locationManager.desiredAccuracy = newValue }
    }
    
    public var distanceFilter: CLLocationDistance {
        get { locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue }
    }
    
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set { locationManager.allowsBackgroundLocationUpdates = newValue }
    }
    
    public var pausesLocationUpdatesAutomatically: Bool {
        get { locationManager.pausesLocationUpdatesAutomatically }
        set { locationManager.pausesLocationUpdatesAutomatically = newValue }
    }
    
    #if os(iOS)
    public var showsBackgroundLocationIndicator: Bool {
        get { locationManager.showsBackgroundLocationIndicator }
        set { locationManager.showsBackgroundLocationIndicator = newValue }
    }
    #endif
    
    // MARK: - Initialization
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        // Configure location manager
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // meters
        
        // Configure for background usage
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        #if os(iOS)
        self.locationManager.showsBackgroundLocationIndicator = false
        #endif
        
        LoggerService.shared.info("✅ UnifiedLocationService initialized - Single CLLocationManager instance", category: .location)
        
        // Configure the RunLoop for timer processing - removed invalid call
        
        // Initialize performance tracking
        trackOperation("initialization", duration: 0, success: true, metadata: [
            "background_enabled": allowsBackgroundLocationUpdates,
            "accuracy": desiredAccuracy,
            "distance_filter": distanceFilter,
            "debounce_window": debounceWindow,
            "burst_mode_interval": burstModeInterval,
            "burst_mode_duration": burstModeDuration
        ])
        
        // Initialize telemetry
        batteryTelemetry = BatteryOptimizationTelemetry()
        lastTelemetryReport = Date()
    }
    
    // MARK: - Delegate Management
    
    public func addLocationDelegate(_ delegate: UnifiedLocationDelegate) {
        delegateQueue.async(flags: .barrier) {
            self.locationDelegates.add(delegate)
        }
        LoggerService.shared.debug("Added location delegate: \(type(of: delegate))", category: .location)
    }
    
    public func removeLocationDelegate(_ delegate: UnifiedLocationDelegate) {
        delegateQueue.async(flags: .barrier) {
            self.locationDelegates.remove(delegate)
        }
    }
    
    public func addBeaconDelegate(_ delegate: UnifiedBeaconDelegate) {
        delegateQueue.async(flags: .barrier) {
            self.beaconDelegates.add(delegate)
        }
        LoggerService.shared.debug("Added beacon delegate: \(type(of: delegate))", category: .beacon)
    }
    
    public func removeBeaconDelegate(_ delegate: UnifiedBeaconDelegate) {
        delegateQueue.async(flags: .barrier) {
            self.beaconDelegates.remove(delegate)
        }
    }
    
    // MARK: - Permission Management
    
    public var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    public func requestWhenInUseAuthorization() {
        LoggerService.shared.info("📍 Requesting WhenInUse authorization", category: .location)
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysAuthorization() {
        LoggerService.shared.info("📍 Requesting Always authorization", category: .location)
        locationManager.requestAlwaysAuthorization()
    }
    
    public func requestLocationPermission() {
        let status = authorizationStatus
        
        switch status {
        case .notDetermined:
            requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            requestAlwaysAuthorization()
        case .authorizedAlways:
            LoggerService.shared.info("✅ Already have Always authorization", category: .location)
        case .denied, .restricted:
            LoggerService.shared.warning("❌ Location permission denied/restricted", category: .location)
        @unknown default:
            LoggerService.shared.warning("Unknown authorization status", category: .location)
        }
    }
    
    // MARK: - Location Services
    
    public static func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public func startUpdatingLocation() {
        LoggerService.shared.info("📍 Starting location updates", category: .location)
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        LoggerService.shared.info("📍 Stopping location updates", category: .location)
        locationManager.stopUpdatingLocation()
    }
    
    /// Start burst mode location monitoring for battery optimization
    /// Alternates between active scanning and rest periods
    public func startBurstModeLocationUpdates() {
        guard !isBurstModeActive else {
            LoggerService.shared.debug("Burst mode already active", category: .location)
            return
        }
        
        let operationId = "burst_mode_start"
        startOperation(operationId)
        
        isBurstModeActive = true
        requestedBurstLocation = false
        
        LoggerService.shared.info("🔋 Starting burst mode location updates (interval: \(burstModeInterval)s, duration: \(burstModeDuration)s)", category: .location)
        
        // Record burst mode activation in telemetry
        performanceQueue.async {
            self.batteryTelemetry.recordBurstModeActivation(duration: self.burstModeInterval)
        }
        
        // Start the first burst immediately
        startBurstScanPeriod()
        
        endOperation(operationId, success: true, metadata: [
            "interval": burstModeInterval,
            "duration": burstModeDuration,
            "battery_optimization": true
        ])
    }
    
    /// Stop burst mode location monitoring
    public func stopBurstModeLocationUpdates() {
        guard isBurstModeActive else {
            LoggerService.shared.debug("Burst mode not active", category: .location)
            return
        }
        
        let operationId = "burst_mode_stop"
        startOperation(operationId)
        
        isBurstModeActive = false
        burstModeTimer?.invalidate()
        burstModeTimer = nil
        locationManager.stopUpdatingLocation()
        
        LoggerService.shared.info("🔋 Stopped burst mode location updates", category: .location)
        
        endOperation(operationId, success: true, metadata: [
            "was_active": true,
            "battery_optimization": true
        ])
    }
    
    /// Start active scanning period in burst mode
    private func startBurstScanPeriod() {
        guard isBurstModeActive else { return }
        
        LoggerService.shared.debug("🔋 Starting burst scan period", category: .location)
        
        // Start location updates for the burst duration
        locationManager.startUpdatingLocation()
        requestedBurstLocation = true
        
        // Schedule stop of active scanning after burst duration
        burstModeTimer = Timer.scheduledTimer(withTimeInterval: burstModeDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.endBurstScanPeriod()
        }
    }
    
    /// End active scanning period and start rest period
    private func endBurstScanPeriod() {
        guard isBurstModeActive else { return }
        
        LoggerService.shared.debug("🔋 Ending burst scan period, starting rest period", category: .location)
        
        // Stop location updates to save battery
        locationManager.stopUpdatingLocation()
        requestedBurstLocation = false
        
        // Schedule next burst after rest interval
        let restPeriod = burstModeInterval - burstModeDuration
        burstModeTimer = Timer.scheduledTimer(withTimeInterval: restPeriod, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.startBurstScanPeriod()
        }
    }
    
    public func requestLocation() {
        LoggerService.shared.info("📍 Requesting single location update", category: .location)
        locationManager.requestLocation()
    }
    
public func getCurrentLocation() async throws -> CLLocation {
        let requestId = UUID()
        let operationId = "get_current_location_\(requestId.uuidString.prefix(8))"
        startOperation(operationId)
        
        // Validate prerequisites
        try validateLocationServices()
        
        // Check if we can cancel any previous task
        await cancelLocationTask()
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use debounce mechanism to prevent excessive location requests
            debounceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LocationError.systemError(underlyingError: NSError(domain: "com.oxii.location", code: -999, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                    return
                }
                
                LoggerService.shared.debug("Debouncing location request", category: .location)
                
                // Cancel any pending debounce timer
                self.locationRequestDebounceTimer?.invalidate()
                
                // If we already have a pending request, use burst mode logic
                if let existingRequestId = self.pendingLocationRequestId {
                    // Store this continuation to be handled when the location arrives
                    self.locationContinuations[requestId] = continuation
                    
                    LoggerService.shared.debug("Using existing pending request: \(existingRequestId)", category: .location)
                    
                    // Record debounced request in telemetry
                    self.performanceQueue.async {
                        self.batteryTelemetry.recordLocationRequest(wasDounced: true)
                    }
                    return
                }
                
                // Set up debounce timer to delay the actual request
                self.pendingLocationRequestId = requestId
                self.locationContinuations[requestId] = continuation
                
                self.locationRequestDebounceTimer = Timer.scheduledTimer(withTimeInterval: self.debounceWindow, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    
                    LoggerService.shared.debug("Debounce window complete, executing location request", category: .location)
                    self.executeLocationRequest(requestId: requestId, operationId: operationId)
                    
                    // Record normal request in telemetry
                    self.performanceQueue.async {
                        self.batteryTelemetry.recordLocationRequest()
                    }
                }
                
                // Track this task so it can be cancelled if needed
                let task = Task { [weak self] in
                    // Timeout after 10 seconds
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    
                    guard let self = self, !Task.isCancelled else { return }
                    
                    self.debounceQueue.async {
                        if let continuation = self.locationContinuations.removeValue(forKey: requestId) {
                            self.endOperation(operationId, success: false, metadata: [
                                "error": "timeout",
                                "timeout_duration": 10.0
                            ])
                            
                            let error = LocationError.timeout(operation: "getCurrentLocation", duration: 10.0)
                            
                            // Record timeout in telemetry
                            self.performanceQueue.async {
                                self.batteryTelemetry.recordTimeout()
                            }
                            
                            // Attempt automatic recovery
                            Task {
                                await ErrorRecoveryManager.shared.attemptRecovery(for: error, context: [
                                    "operation_id": operationId,
                                    "request_id": requestId.uuidString
                                ])
                            }
                            
                            continuation.resume(throwing: error)
                            
                            // Clear pending request if this was the pending one
                            if self.pendingLocationRequestId == requestId {
                                self.pendingLocationRequestId = nil
                            }
                        }
                    }
                }
                
                // Store task for potential cancellation
                self.taskQueue.async(flags: .barrier) {
                    self.locationTasks[requestId] = task
                }
            }
        }
    }
    
    private func executeLocationRequest(requestId: UUID, operationId: String) {
        LoggerService.shared.debug("Executing location request: \(requestId)", category: .location)
        pendingLocationRequestId = nil
        locationManager.requestLocation()
    }
    
    /// Cancel a specific location task by ID
    public func cancelLocationRequest(requestId: UUID) async -> Bool {
        return await withCheckedContinuation { continuation in
            taskQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                let wasCancelled: Bool
                if let task = self.locationTasks.removeValue(forKey: requestId) {
                    task.cancel()
                    self.cancellables[requestId] = true
                    
                    // Cancel the continuation if it exists
                    if let locationContinuation = self.locationContinuations.removeValue(forKey: requestId) {
                        let cancellationError = LocationError.systemError(
                            underlyingError: CancellationError()
                        )
                        locationContinuation.resume(throwing: cancellationError)
                    }
                    
                    LoggerService.shared.debug("Cancelled location request: \(requestId)", category: .location)
                    
                    // Record cancellation in telemetry
                    self.performanceQueue.async {
                        self.batteryTelemetry.recordCancelledRequest()
                    }
                    
                    wasCancelled = true
                } else {
                    wasCancelled = false
                }
                
                continuation.resume(returning: wasCancelled)
            }
        }
    }
    
    /// Cancel all pending location tasks
    private func cancelLocationTask() async {
        await withCheckedContinuation { continuation in
            taskQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: ())
                    return
                }
                
                let taskCount = self.locationTasks.count
                let continuationCount = self.locationContinuations.count
                
                // Cancel all pending tasks
                for (id, task) in self.locationTasks {
                    task.cancel()
                    self.cancellables[id] = true
                }
                self.locationTasks.removeAll()
                
                // Cancel all pending continuations with proper error
                let cancellationError = LocationError.systemError(
                    underlyingError: CancellationError()
                )
                
                for (_, locationContinuation) in self.locationContinuations {
                    locationContinuation.resume(throwing: cancellationError)
                }
                self.locationContinuations.removeAll()
                
                // Clear pending state
                self.pendingLocationRequestId = nil
                self.locationRequestDebounceTimer?.invalidate()
                self.locationRequestDebounceTimer = nil
                
                LoggerService.shared.info(
                    "Cancelled all location operations (\(taskCount) tasks, \(continuationCount) continuations)",
                    category: .location
                )
                
                continuation.resume(returning: ())
            }
        }
    }
    
    /// Cancel all operations and cleanup resources
    public func cancelAllOperations() async {
        await cancelLocationTask()
        
        // Stop burst mode if active
        if isBurstModeActive {
            stopBurstModeLocationUpdates()
        }
        
        // Stop any active location updates
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        LoggerService.shared.info("✅ All location operations cancelled and resources cleaned up", category: .location)
    }
    
    // MARK: - Beacon Monitoring
    
    public func startMonitoring(for region: CLBeaconRegion) {
        let operationId = "start_monitoring_\(region.identifier)"
        startOperation(operationId)
        
        do {
            try validateBeaconMonitoring()
            try validateRegionConflicts(for: region)
        } catch let error as LocationError {
            LoggerService.shared.error("Failed to validate beacon monitoring", error: error, category: .beacon)
            endOperation(operationId, success: false, metadata: ["validation_error": error.debugDescription])
            
            // Attempt recovery
            Task {
                await ErrorRecoveryManager.shared.attemptRecovery(for: error, context: [
                    "operation": "startMonitoring",
                    "region": region.identifier
                ])
            }
            return
        } catch {
            let locationError = LocationError.systemError(underlyingError: error)
            LoggerService.shared.error("System error in beacon monitoring validation", error: locationError, category: .beacon)
            endOperation(operationId, success: false, metadata: ["system_error": error.localizedDescription])
            return
        }
        
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.monitoredBeaconRegions[region.identifier] = region
            
            // Configure region
            region.notifyEntryStateOnDisplay = true
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            self.locationManager.startMonitoring(for: region)
            LoggerService.shared.info("📡 Started monitoring beacon region: \(region.identifier)", category: .beacon)
            
            // Request initial state
            self.locationManager.requestState(for: region)
            
            self.endOperation(operationId, success: true, metadata: [
                "region_identifier": region.identifier,
                "uuid": region.uuid.uuidString,
                "major": region.major?.intValue ?? "any",
                "minor": region.minor?.intValue ?? "any"
            ])
        }
    }
    
    public func stopMonitoring(for region: CLBeaconRegion) {
        monitoredBeaconRegions.removeValue(forKey: region.identifier)
        locationManager.stopMonitoring(for: region)
        LoggerService.shared.info("📡 Stopped monitoring beacon region: \(region.identifier)", category: .beacon)
    }
    
    public func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredBeaconRegions.removeAll()
        LoggerService.shared.info("📡 Stopped monitoring all regions", category: .beacon)
    }
    
    public var monitoredRegions: Set<CLRegion> {
        return locationManager.monitoredRegions
    }
    
    public static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: regionClass)
    }
    
    // MARK: - Beacon Ranging
    
    public func startRangingBeacons(in region: CLBeaconRegion) {
        guard CLLocationManager.isRangingAvailable() else {
            LoggerService.shared.warning("Ranging not available on this device", category: .beacon)
            return
        }
        
        let operationId = "start_ranging_\(region.identifier)"
        startOperation(operationId)
        
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.rangedBeaconRegions[region.identifier] = region
            
            if #available(iOS 13.0, *) {
                self.locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
            } else {
                self.locationManager.startRangingBeacons(in: region)
            }
            
            LoggerService.shared.info("📡 Started ranging beacons in region: \(region.identifier)", category: .beacon)
            
            self.endOperation(operationId, success: true, metadata: [
                "region_identifier": region.identifier,
                "uuid": region.uuid.uuidString,
                "ranging_available": CLLocationManager.isRangingAvailable()
            ])
        }
    }
    
    public func stopRangingBeacons(in region: CLBeaconRegion) {
        rangedBeaconRegions.removeValue(forKey: region.identifier)
        
        if #available(iOS 13.0, *) {
            locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        } else {
            locationManager.stopRangingBeacons(in: region)
        }
        
        LoggerService.shared.info("📡 Stopped ranging beacons in region: \(region.identifier)", category: .beacon)
    }
    
    public func stopRangingAllBeacons() {
        for region in rangedBeaconRegions.values {
            stopRangingBeacons(in: region)
        }
    }
    
    public static func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    // MARK: - Region State
    
    public func requestState(for region: CLRegion) {
        locationManager.requestState(for: region)
    }
    
    // MARK: - Significant Location Changes
    
    public func startMonitoringSignificantLocationChanges() {
        let operationId = "significant_location_start"
        startOperation(operationId)
        
        locationManager.startMonitoringSignificantLocationChanges()
        LoggerService.shared.info("📍 Starting significant location change monitoring", category: .location)
        
        endOperation(operationId, success: true)
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        let operationId = "significant_location_stop"
        startOperation(operationId)
        
        locationManager.stopMonitoringSignificantLocationChanges()
        LoggerService.shared.info("📍 Stopping significant location change monitoring", category: .location)
        
        endOperation(operationId, success: true)
    }
    
    public static func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
}

// MARK: - CLLocationManagerDelegate

extension UnifiedLocationService: CLLocationManagerDelegate {
    
    // MARK: Location Updates
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Fulfill any pending continuations and track performance
        if !locationContinuations.isEmpty, let location = locations.last {
            // Remove any tasks associated with these continuations
            let requestIds = Array(locationContinuations.keys)
            taskQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                for requestId in requestIds {
                    self.locationTasks.removeValue(forKey: requestId)
                    self.cancellables.removeValue(forKey: requestId)
                }
            }
            
            // Process all pending continuations
            for (requestId, continuation) in locationContinuations {
                let operationId = "get_current_location_\(requestId.uuidString.prefix(8))"
                endOperation(operationId, success: true, metadata: [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy,
                    "timestamp": location.timestamp.timeIntervalSince1970,
                    "debounced": true
                ])
                
                // Record successful request in telemetry
                performanceQueue.async {
                    self.batteryTelemetry.recordSuccess()
                }
                
                continuation.resume(returning: location)
            }
            locationContinuations.removeAll()
            pendingLocationRequestId = nil
        }
        
        // Notify all delegates
        delegateQueue.sync {
            for delegate in locationDelegates.allObjects {
                if let locationDelegate = delegate as? UnifiedLocationDelegate {
                    DispatchQueue.main.async {
                        locationDelegate.unifiedLocationService(self, didUpdateLocations: locations)
                    }
                }
            }
        }
        
        let logCategory = isBurstModeActive ? "🔋 Burst mode location updated" : "📍 Location updated"
        LoggerService.shared.debug("\(logCategory): \(locations.count) location(s)", category: .location)
        
        // Log telemetry report if interval has passed
        logTelemetryReportIfNeeded()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Convert to LocationError with context
        let locationError = convertToLocationError(error)
        
        // Fail any pending continuations and track errors
        for (requestId, continuation) in locationContinuations {
            let operationId = "get_current_location_\(requestId.uuidString.prefix(8))"
            endOperation(operationId, success: false, metadata: [
                "error_domain": error._domain,
                "error_code": error._code,
                "error_description": error.localizedDescription,
                "location_error_code": locationError.code
            ])
            
            // Attempt recovery before failing continuation
            Task {
                let recovered = await ErrorRecoveryManager.shared.attemptRecovery(for: locationError, context: [
                    "operation": "location_update",
                    "request_id": requestId.uuidString
                ])
                
                if !recovered {
                    continuation.resume(throwing: locationError)
                }
            }
        }
        locationContinuations.removeAll()
        
        // Notify all delegates
        delegateQueue.sync {
            for delegate in locationDelegates.allObjects {
                if let locationDelegate = delegate as? UnifiedLocationDelegate {
                    DispatchQueue.main.async {
                        locationDelegate.unifiedLocationService(self, didFailWithError: error)
                    }
                }
            }
        }
        
        LoggerService.shared.error("Location error", error: error, category: .location)
    }
    
    // MARK: Authorization
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        // Notify all delegates
        delegateQueue.sync {
            for delegate in locationDelegates.allObjects {
                if let locationDelegate = delegate as? UnifiedLocationDelegate {
                    DispatchQueue.main.async {
                        locationDelegate.unifiedLocationService(self, didChangeAuthorization: status)
                    }
                }
            }
        }
        
        LoggerService.shared.info("📍 Authorization changed: \(status.rawValue)", category: .location)
        
        // Handle authorization changes
        switch status {
        case .authorizedAlways:
            LoggerService.shared.info("✅ Got Always authorization", category: .location)
        case .authorizedWhenInUse:
            LoggerService.shared.info("📍 Got WhenInUse authorization", category: .location)
        case .denied, .restricted:
            LoggerService.shared.warning("❌ Location authorization denied/restricted", category: .location)
        default:
            break
        }
    }
    
    // MARK: Beacon Monitoring
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        
        delegateQueue.sync {
            for delegate in beaconDelegates.allObjects {
                if let beaconDelegate = delegate as? UnifiedBeaconDelegate {
                    DispatchQueue.main.async {
                        beaconDelegate.unifiedLocationService(self, didEnterRegion: beaconRegion)
                    }
                }
            }
        }
        
        LoggerService.shared.info("📡 Entered region: \(region.identifier)", category: .beacon)
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        
        delegateQueue.sync {
            for delegate in beaconDelegates.allObjects {
                if let beaconDelegate = delegate as? UnifiedBeaconDelegate {
                    DispatchQueue.main.async {
                        beaconDelegate.unifiedLocationService(self, didExitRegion: beaconRegion)
                    }
                }
            }
        }
        
        LoggerService.shared.info("📡 Exited region: \(region.identifier)", category: .beacon)
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        
        delegateQueue.sync {
            for delegate in beaconDelegates.allObjects {
                if let beaconDelegate = delegate as? UnifiedBeaconDelegate {
                    DispatchQueue.main.async {
                        beaconDelegate.unifiedLocationService(self, didDetermineState: state, for: beaconRegion)
                    }
                }
            }
        }
        
        let stateString = state == .inside ? "inside" : state == .outside ? "outside" : "unknown"
        LoggerService.shared.info("📡 Region state: \(region.identifier) = \(stateString)", category: .beacon)
    }
    
    // MARK: Beacon Ranging
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // FIX: Critical check for empty identifier before processing
        if region.identifier.isEmpty {
            LoggerService.shared.error("🚨 CRITICAL: Empty region identifier detected in ranging callback! This should be impossible after region validation fix.", category: .beacon)
            LoggerService.shared.error("📡 Region details: UUID=\(region.uuid.uuidString), Major=\(region.major?.stringValue ?? "nil"), Minor=\(region.minor?.stringValue ?? "nil"), Beacons=\(beacons.count)", category: .beacon)
            return
        }
        
        // Enhanced logging for debugging
        LoggerService.shared.debug("🔍 UnifiedLocationService ranging: \(region.identifier) with \(beacons.count) beacons", category: .beacon)
        
        delegateQueue.sync {
            for delegate in beaconDelegates.allObjects {
                if let beaconDelegate = delegate as? UnifiedBeaconDelegate {
                    DispatchQueue.main.async {
                        beaconDelegate.unifiedLocationService(self, didRangeBeacons: beacons, in: region)
                    }
                }
            }
        }
        
        if !beacons.isEmpty {
            LoggerService.shared.debug("📡 Ranged \(beacons.count) beacon(s) in \(region.identifier)", category: .beacon)
        }
    }
    
    // MARK: Error Handling
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let regionIdentifier = region?.identifier ?? "unknown"
        let locationError = LocationError.monitoringFailed(region: regionIdentifier, underlyingError: error)
        
        LoggerService.shared.error("Monitoring failed for region: \(regionIdentifier)", error: locationError, category: .beacon)
        
        // Attempt recovery
        Task {
            await ErrorRecoveryManager.shared.attemptRecovery(for: locationError, context: [
                "operation": "monitoring",
                "region": regionIdentifier,
                "underlying_error": error.localizedDescription
            ])
        }
    }
}

// MARK: - Deprecated Backward Compatibility APIs

extension UnifiedLocationService {
    
    /// Deprecated access to internal CLLocationManager for backward compatibility
    /// Use UnifiedLocationService methods instead of direct CLLocationManager access
    @available(*, deprecated, message: "Direct access to CLLocationManager is deprecated. Use UnifiedLocationService methods instead.")
    public var coreLocationManager: CLLocationManager {
        LoggerService.shared.warning("⚠️ DEPRECATED: Direct CLLocationManager access. Migrate to UnifiedLocationService APIs.", category: .location)
        return locationManager
    }
}

// MARK: - Performance Monitoring

extension UnifiedLocationService: LocationServiceMetrics {
    
    /// Track operation performance with battery impact estimation
    public func trackOperation(_ operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]?) {
        performanceQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Update battery impact score based on operation type
            let impact = self.calculateBatteryImpact(operation: operation, duration: duration)
            self.batteryImpactScore += impact
            
            let logMetadata = metadata ?? [:]
            let fullMetadata = logMetadata.merging([
                "duration_ms": duration * 1000,
                "battery_impact": impact,
                "cumulative_impact": self.batteryImpactScore
            ]) { _, new in new }
            
            LoggerService.shared.info("⚡ PERFORMANCE: \(operation) - \(success ? "SUCCESS" : "FAILED") (\(String(format: "%.2f", duration * 1000))ms)", category: .location)
            
            if let metadataData = try? JSONSerialization.data(withJSONObject: fullMetadata),
               let metadataString = String(data: metadataData, encoding: .utf8) {
                LoggerService.shared.debug("📊 METRICS: \(metadataString)", category: .location)
            }
        }
    }
    
    /// Get current battery impact estimate (0.0 to 1.0)
    public var batteryImpactEstimate: Double {
        return min(batteryImpactScore / 100.0, 1.0) // Normalize to 0-1 scale
    }
    
    /// Get comprehensive usage statistics
    public func getUsageStatistics() -> [String: Any] {
        return performanceQueue.sync {
            var stats: [String: Any] = [
                "battery_impact_score": batteryImpactScore,
                "battery_impact_estimate": batteryImpactEstimate,
                "monitored_regions_count": monitoredBeaconRegions.count,
                "ranged_regions_count": rangedBeaconRegions.count,
                "location_delegates_count": locationDelegates.count,
                "beacon_delegates_count": beaconDelegates.count,
                "authorization_status": authorizationStatus.rawValue,
                "desired_accuracy": desiredAccuracy,
                "distance_filter": distanceFilter,
                "background_updates_enabled": allowsBackgroundLocationUpdates,
                "debounce_window": debounceWindow,
                "burst_mode_interval": burstModeInterval,
                "burst_mode_duration": burstModeDuration,
                "pending_location_requests": locationContinuations.count,
                "is_burst_mode_active": isBurstModeActive,
                "has_pending_debounce": pendingLocationRequestId != nil,
                "requested_burst_location": requestedBurstLocation
            ]
            
            // Add task counts and cancellation status
            taskQueue.sync {
                stats["active_location_tasks"] = locationTasks.count
                stats["cancellable_tasks"] = cancellables.count
                stats["cancelled_task_ids"] = Array(cancellables.keys).map { $0.uuidString }
            }
            
            return stats
        }
    }
    
    /// Check if a specific request was cancelled
    public func isRequestCancelled(_ requestId: UUID) -> Bool {
        return taskQueue.sync {
            return cancellables[requestId] == true
        }
    }
    
    /// Clean up cancelled request state
    public func cleanupCancelledRequests() {
        taskQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let cleanedCount = self.cancellables.count
            self.cancellables.removeAll()
            
            if cleanedCount > 0 {
                LoggerService.shared.debug(
                    "Cleaned up \(cleanedCount) cancelled request records",
                    category: .location
                )
            }
        }
    }
    
    // MARK: - Private Performance Helpers
    
    private func startOperation(_ operationId: String) {
        performanceQueue.async { [weak self] in
            self?.operationStartTimes[operationId] = Date()
        }
    }
    
    private func endOperation(_ operationId: String, success: Bool, metadata: [String: Any]? = nil) {
        performanceQueue.async { [weak self] in
            guard let self = self,
                  let startTime = self.operationStartTimes.removeValue(forKey: operationId) else {
                return
            }
            
            let duration = Date().timeIntervalSince(startTime)
            self.trackOperation(operationId, duration: duration, success: success, metadata: metadata)
        }
    }
    
    private func calculateBatteryImpact(operation: String, duration: TimeInterval) -> Double {
        // Battery impact estimation based on operation type and duration
        let baseImpact: Double
        
        switch operation {
        case "initialization":
            baseImpact = 0.1
        case let op where op.contains("monitoring"):
            baseImpact = 0.5 * duration // Monitoring has moderate continuous impact
        case let op where op.contains("ranging"):
            baseImpact = 2.0 * duration // Ranging has high impact due to active scanning
        case let op where op.contains("location"):
            if isBurstModeActive {
                // Burst mode reduces overall battery impact by 40%
                baseImpact = 0.6 * duration 
            } else if op.contains("debounce") {
                // Debounced requests have lower impact due to consolidation
                baseImpact = 0.8 * duration 
            } else {
                baseImpact = 1.0 * duration // Regular location updates have moderate impact
            }
        case "significant_location_start", "significant_location_stop":
            baseImpact = 0.2 // Low impact for significant location changes
        case "burst_mode_start", "burst_mode_stop":
            baseImpact = 0.3 // Minimal impact for burst mode management
        default:
            baseImpact = 0.3 * duration // Default moderate impact
        }
        
        return baseImpact
    }
}

// MARK: - Battery Optimization Telemetry

/// Telemetry structure for battery optimization tracking
private struct BatteryOptimizationTelemetry {
    var totalLocationRequests: Int = 0
    var debouncedRequests: Int = 0
    var burstModeActivations: Int = 0
    var totalBurstModeTime: TimeInterval = 0
    var batterySavingsEstimate: Double = 0.0
    var averageRequestInterval: TimeInterval = 0
    var requestTimes: [Date] = []
    var cancelledRequests: Int = 0
    var timeoutErrors: Int = 0
    var successfulRequests: Int = 0
    
    mutating func recordLocationRequest(wasDounced: Bool = false) {
        totalLocationRequests += 1
        if wasDounced {
            debouncedRequests += 1
        }
        
        let now = Date()
        requestTimes.append(now)
        
        // Keep only last 50 request times for interval calculation
        if requestTimes.count > 50 {
            requestTimes.removeFirst()
        }
        
        // Calculate average request interval
        if requestTimes.count > 1 {
            let intervals = zip(requestTimes.dropFirst(), requestTimes.dropLast())
                .map { $0.timeIntervalSince($1) }
            averageRequestInterval = intervals.reduce(0, +) / Double(intervals.count)
        }
    }
    
    mutating func recordBurstModeActivation(duration: TimeInterval) {
        burstModeActivations += 1
        totalBurstModeTime += duration
    }
    
    mutating func recordCancelledRequest() {
        cancelledRequests += 1
    }
    
    mutating func recordTimeout() {
        timeoutErrors += 1
    }
    
    mutating func recordSuccess() {
        successfulRequests += 1
    }
    
    mutating func calculateBatterySavings(baselineImpact: Double, optimizedImpact: Double) {
        if baselineImpact > 0 {
            batterySavingsEstimate = ((baselineImpact - optimizedImpact) / baselineImpact) * 100
        }
    }
    
    func generateReport() -> [String: Any] {
        let successRate = totalLocationRequests > 0 ? 
            (Double(successfulRequests) / Double(totalLocationRequests)) * 100 : 0
        let debounceEfficiency = totalLocationRequests > 0 ?
            (Double(debouncedRequests) / Double(totalLocationRequests)) * 100 : 0
        
        return [
            "total_location_requests": totalLocationRequests,
            "debounced_requests": debouncedRequests,
            "debounce_efficiency_percent": debounceEfficiency,
            "burst_mode_activations": burstModeActivations,
            "total_burst_mode_time_seconds": totalBurstModeTime,
            "average_request_interval_seconds": averageRequestInterval,
            "cancelled_requests": cancelledRequests,
            "timeout_errors": timeoutErrors,
            "successful_requests": successfulRequests,
            "success_rate_percent": successRate,
            "battery_savings_estimate_percent": batterySavingsEstimate,
            "recent_request_frequency": requestTimes.count > 1 ? 
                Double(requestTimes.count) / Date().timeIntervalSince(requestTimes.first ?? Date()) * 60 : 0 // requests per minute
        ]
    }
}

extension UnifiedLocationService {
    
    /// Get battery optimization telemetry report
    public func getBatteryOptimizationReport() -> [String: Any] {
        return performanceQueue.sync {
            var report = batteryTelemetry.generateReport()
            report["current_battery_impact_score"] = batteryImpactScore
            report["current_battery_impact_estimate"] = batteryImpactEstimate
            report["telemetry_period_minutes"] = Date().timeIntervalSince(lastTelemetryReport) / 60
            report["burst_mode_currently_active"] = isBurstModeActive
            report["has_pending_debounce"] = pendingLocationRequestId != nil
            
            // Calculate theoretical baseline impact without optimizations
            let baselineImpact = Double(batteryTelemetry.totalLocationRequests) * 1.0 // 1.0 impact per request
            report["theoretical_baseline_impact"] = baselineImpact
            report["optimization_effectiveness_percent"] = baselineImpact > 0 ? 
                ((baselineImpact - batteryImpactScore) / baselineImpact) * 100 : 0
            
            return report
        }
    }
    
    /// Reset telemetry counters (useful for testing or periodic resets)
    public func resetBatteryTelemetry() {
        performanceQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let oldReport = self.batteryTelemetry.generateReport()
            self.batteryTelemetry = BatteryOptimizationTelemetry()
            self.batteryImpactScore = 0.0
            self.lastTelemetryReport = Date()
            
            LoggerService.shared.info(
                "🔋 Battery telemetry reset. Previous session: \(oldReport)",
                category: .location
            )
        }
    }
    
    /// Log periodic telemetry report if interval has passed
    private func logTelemetryReportIfNeeded() {
        performanceQueue.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            if now.timeIntervalSince(self.lastTelemetryReport) >= self.telemetryReportInterval {
                let report = self.getBatteryOptimizationReport()
                
                if let reportData = try? JSONSerialization.data(withJSONObject: report),
                   let reportString = String(data: reportData, encoding: .utf8) {
                    LoggerService.shared.info(
                        "🔋 BATTERY OPTIMIZATION TELEMETRY: \(reportString)",
                        category: .location
                    )
                }
                
                self.lastTelemetryReport = now
            }
        }
    }
}

// MARK: - Service Status

extension UnifiedLocationService {
    
    /// Get comprehensive service status
    public var serviceStatus: String {
        return """
        UnifiedLocationService Status:
        - Authorization: \(authorizationStatus.rawValue)
        - Location Services: \(Self.locationServicesEnabled() ? "Enabled" : "Disabled")
        - Monitored Regions: \(monitoredBeaconRegions.count)
        - Ranged Regions: \(rangedBeaconRegions.count)
        - Location Delegates: \(locationDelegates.count)
        - Beacon Delegates: \(beaconDelegates.count)
        - Accuracy: \(desiredAccuracy)
        - Distance Filter: \(distanceFilter)m
        - Background Updates: \(allowsBackgroundLocationUpdates)
        - Burst Mode: \(isBurstModeActive ? "Active" : "Inactive")
        - Debounce Window: \(debounceWindow)s
        - Battery Impact: \(String(format: "%.2f%%", batteryImpactEstimate * 100))
        """
    }
    
    public func logStatus() {
        LoggerService.shared.info(serviceStatus, category: .location)
    }
}

// MARK: - Error Handling & Validation

extension UnifiedLocationService {
    
    /// Validate location services prerequisites
    /// - Throws: LocationError if validation fails
    private func validateLocationServices() throws {
        // Check if location services are enabled system-wide
        guard Self.locationServicesEnabled() else {
            throw LocationError.locationServicesDisabled
        }
        
        // Check authorization status
        switch authorizationStatus {
        case .notDetermined:
            throw LocationError.permissionNotDetermined
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        case .authorizedWhenInUse:
            // WhenInUse is sufficient for basic location requests
            break
        case .authorizedAlways:
            // Always permission is ideal
            break
        @unknown default:
            throw LocationError.unknown(code: Int(authorizationStatus.rawValue), description: "Unknown authorization status")
        }
    }
    
    /// Validate beacon monitoring prerequisites
    /// - Throws: LocationError if validation fails
    private func validateBeaconMonitoring() throws {
        // First validate basic location services
        try validateLocationServices()
        
        // Check beacon monitoring availability
        guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
            throw LocationError.beaconMonitoringUnavailable
        }
        
        // Check region limit (iOS allows max 20 monitored regions)
        if monitoredBeaconRegions.count >= 20 {
            throw LocationError.regionLimitExceeded
        }
        
        // For beacon monitoring, Always permission is preferred
        #if os(iOS)
        if authorizationStatus == .authorizedWhenInUse {
            throw LocationError.backgroundExecutionDenied
        }
        #endif
    }
    
    /// Validate region conflicts and identifier uniqueness
    /// - Parameter region: The region to validate
    /// - Throws: LocationError if validation fails
    private func validateRegionConflicts(for region: CLBeaconRegion) throws {
        // Check for empty identifier (major cause of iOS region conflicts)
        guard !region.identifier.isEmpty else {
            throw LocationError.invalidConfiguration(reason: "Region identifier cannot be empty")
        }
        
        // Check for identifier conflicts
        if monitoredBeaconRegions[region.identifier] != nil {
            LoggerService.shared.warning("⚠️ Region identifier conflict detected: \(region.identifier)", category: .beacon)
            throw LocationError.invalidConfiguration(reason: "Region identifier '\(region.identifier)' already in use")
        }
        
        // Check for duplicate UUID monitoring (can cause iOS region confusion)
        let existingRegionsWithSameUUID = monitoredBeaconRegions.values.filter { existingRegion in
            existingRegion.uuid == region.uuid &&
            existingRegion.major == region.major &&
            existingRegion.minor == region.minor
        }
        
        if !existingRegionsWithSameUUID.isEmpty {
            LoggerService.shared.warning("⚠️ Duplicate region UUID detected: \(region.uuid.uuidString)", category: .beacon)
            // This is a warning, not a hard error, as some apps may need duplicate UUIDs with different identifiers
        }
        
        // Warn if approaching region limit
        let currentRegionCount = locationManager.monitoredRegions.count
        if currentRegionCount >= 18 { // Warn at 18/20 limit
            LoggerService.shared.warning("⚠️ Approaching iOS region limit: \(currentRegionCount)/20 regions", category: .beacon)
        }
        
        LoggerService.shared.debug("✅ Region validation passed for: \(region.identifier)", category: .beacon)
    }
    
    /// Validate beacon ranging prerequisites
    /// - Throws: LocationError if validation fails
    private func validateBeaconRanging() throws {
        // First validate basic location services
        try validateLocationServices()
        
        // Check ranging availability
        guard CLLocationManager.isRangingAvailable() else {
            throw LocationError.beaconRangingUnavailable
        }
    }
    
    /// Convert CLError and other system errors to LocationError
    /// - Parameter error: The system error to convert
    /// - Returns: Appropriate LocationError with context
    private func convertToLocationError(_ error: Error) -> LocationError {
        // Handle CLError specifically
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                return LocationError.locationUpdateFailed(underlyingError: error)
            case .denied:
                return LocationError.permissionDenied
            case .network:
                return LocationError.networkUnavailable
            case .headingFailure:
                return LocationError.unsupportedDevice
            case .rangingUnavailable:
                return LocationError.beaconRangingUnavailable
            case .rangingFailure:
                return LocationError.rangingFailed(region: "unknown", underlyingError: error)
            case .regionMonitoringDenied:
                return LocationError.permissionDenied
            case .regionMonitoringFailure:
                return LocationError.monitoringFailed(region: "unknown", underlyingError: error)
            case .regionMonitoringSetupDelayed:
                return LocationError.monitoringFailed(region: "unknown", underlyingError: error)
            case .regionMonitoringResponseDelayed:
                return LocationError.timeout(operation: "region_monitoring", duration: 0)
            default:
                return LocationError.systemError(underlyingError: error)
            }
        }
        
        // Handle NSError with specific domains
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "kCLErrorDomain":
                return convertCLErrorCode(nsError.code, underlyingError: error)
            case NSURLErrorDomain:
                return LocationError.networkUnavailable
            default:
                return LocationError.systemError(underlyingError: error)
            }
        }
        
        // Generic fallback
        return LocationError.systemError(underlyingError: error)
    }
    
    /// Convert specific CLError codes to LocationError
    /// - Parameters:
    ///   - code: The CLError code
    ///   - underlyingError: The original error
    /// - Returns: Appropriate LocationError
    private func convertCLErrorCode(_ code: Int, underlyingError: Error) -> LocationError {
        // Map CLError.Code raw values to LocationError
        switch code {
        case 0: // kCLErrorLocationUnknown
            return LocationError.locationUpdateFailed(underlyingError: underlyingError)
        case 1: // kCLErrorDenied
            return LocationError.permissionDenied
        case 2: // kCLErrorNetwork
            return LocationError.networkUnavailable
        case 3: // kCLErrorHeadingFailure
            return LocationError.unsupportedDevice
        case 11: // kCLErrorRangingUnavailable
            return LocationError.beaconRangingUnavailable
        case 12: // kCLErrorRangingFailure
            return LocationError.rangingFailed(region: "unknown", underlyingError: underlyingError)
        case 5: // kCLErrorRegionMonitoringDenied
            return LocationError.permissionDenied
        case 6: // kCLErrorRegionMonitoringFailure
            return LocationError.monitoringFailed(region: "unknown", underlyingError: underlyingError)
        case 7: // kCLErrorRegionMonitoringSetupDelayed
            return LocationError.monitoringFailed(region: "unknown", underlyingError: underlyingError)
        case 8: // kCLErrorRegionMonitoringResponseDelayed
            return LocationError.timeout(operation: "region_monitoring", duration: 30.0)
        default:
            return LocationError.unknown(code: code, description: underlyingError.localizedDescription)
        }
    }
}
