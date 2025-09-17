//
//  UnifiedLocationService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//  Purpose: Single consolidated CLLocationManager instance for entire app
//

import Foundation
import CoreLocation

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
public final class UnifiedLocationService: NSObject {
    
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
        
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuations[requestId] = continuation
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if let continuation = self?.locationContinuations.removeValue(forKey: requestId) {
                    continuation.resume(throwing: NSError(
                        domain: "UnifiedLocationService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Location request timed out"]
                    ))
                }
            }
        }
    }
    
    // MARK: - Beacon Monitoring
    
    public func startMonitoring(for region: CLBeaconRegion) {
        monitoredBeaconRegions[region.identifier] = region
        
        // Configure region
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        LoggerService.shared.info("📡 Started monitoring beacon region: \(region.identifier)", category: .beacon)
        
        // Request initial state
        locationManager.requestState(for: region)
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
        
        rangedBeaconRegions[region.identifier] = region
        
        if #available(iOS 13.0, *) {
            locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
        } else {
            locationManager.startRangingBeacons(in: region)
        }
        
        LoggerService.shared.info("📡 Started ranging beacons in region: \(region.identifier)", category: .beacon)
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
}

// MARK: - CLLocationManagerDelegate

extension UnifiedLocationService: CLLocationManagerDelegate {
    
    // MARK: Location Updates
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Fulfill any pending continuations
        if !locationContinuations.isEmpty, let location = locations.last {
            for (_, continuation) in locationContinuations {
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
        // Fail any pending continuations
        for (_, continuation) in locationContinuations {
            continuation.resume(throwing: error)
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
        LoggerService.shared.error("Monitoring failed for region: \(region?.identifier ?? "unknown")", error: error, category: .beacon)
        
        // Notify as general error
        locationManager(manager, didFailWithError: error)
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
