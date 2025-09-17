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
    
    /// Performance monitoring and battery tracking
    private var operationStartTimes: [String: Date] = [:]
    private var batteryImpactScore: Double = 0.0
    private let performanceQueue = DispatchQueue(label: "com.oxii.location.performance", qos: .utility)
    
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
        
        // Initialize performance tracking
        trackOperation("initialization", duration: 0, success: true, metadata: [
            "background_enabled": allowsBackgroundLocationUpdates,
            "accuracy": desiredAccuracy,
            "distance_filter": distanceFilter
        ])
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
        
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuations[requestId] = continuation
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if let continuation = self?.locationContinuations.removeValue(forKey: requestId) {
                    self?.endOperation(operationId, success: false, metadata: [
                        "error": "timeout",
                        "timeout_duration": 10.0
                    ])
                    
                    let error = LocationError.timeout(operation: "getCurrentLocation", duration: 10.0)
                    
                    // Attempt automatic recovery
                    Task {
                        await ErrorRecoveryManager.shared.attemptRecovery(for: error, context: [
                            "operation_id": operationId,
                            "request_id": requestId.uuidString
                        ])
                    }
                    
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Beacon Monitoring
    
    public func startMonitoring(for region: CLBeaconRegion) {
        let operationId = "start_monitoring_\(region.identifier)"
        startOperation(operationId)
        
        do {
            try validateBeaconMonitoring()
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
            for (requestId, continuation) in locationContinuations {
                let operationId = "get_current_location_\(requestId.uuidString.prefix(8))"
                endOperation(operationId, success: true, metadata: [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy,
                    "timestamp": location.timestamp.timeIntervalSince1970
                ])
                continuation.resume(returning: location)
            }
            locationContinuations.removeAll()
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
        
        LoggerService.shared.debug("📍 Location updated: \(locations.count) location(s)", category: .location)
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
            return [
                "battery_impact_score": batteryImpactScore,
                "battery_impact_estimate": batteryImpactEstimate,
                "monitored_regions_count": monitoredBeaconRegions.count,
                "ranged_regions_count": rangedBeaconRegions.count,
                "location_delegates_count": locationDelegates.count,
                "beacon_delegates_count": beaconDelegates.count,
                "authorization_status": authorizationStatus.rawValue,
                "desired_accuracy": desiredAccuracy,
                "distance_filter": distanceFilter,
                "background_updates_enabled": allowsBackgroundLocationUpdates
            ]
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
            baseImpact = 1.0 * duration // Location updates have moderate impact
        case "significant_location_start", "significant_location_stop":
            baseImpact = 0.2 // Low impact for significant location changes
        default:
            baseImpact = 0.3 * duration // Default moderate impact
        }
        
        return baseImpact
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
        guard Self.isMonitoringAvailable(for: CLBeaconRegion.self) else {
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
    
    /// Validate beacon ranging prerequisites
    /// - Throws: LocationError if validation fails
    private func validateBeaconRanging() throws {
        // First validate basic location services
        try validateLocationServices()
        
        // Check ranging availability
        guard Self.isRangingAvailable() else {
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
