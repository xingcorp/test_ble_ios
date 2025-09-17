//
//  SLCSService.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

public protocol SLCSServiceDelegate: AnyObject {
    func didTriggerSignificantChange()
}

/// SLCS (Significant Location Change Service) using UnifiedLocationService
/// Provides battery-efficient location monitoring for major location changes
public final class SLCSService: NSObject {
    
    // MARK: - Dependencies
    
    /// Unified location service for significant location change monitoring
    private let unifiedLocationService: SignificantLocationChangeProvider & UnifiedLocationProvider
    
    /// Delegate for significant location change events
    public weak var delegate: SLCSServiceDelegate?
    
    /// Service state tracking
    private var isMonitoring: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize with UnifiedLocationService (recommended)
    /// - Parameter unifiedLocationService: The unified location service to use
    public init(unifiedLocationService: (SignificantLocationChangeProvider & UnifiedLocationProvider) = UnifiedLocationService.shared) {
        self.unifiedLocationService = unifiedLocationService
        super.init()
        
        // Register as location delegate if it's UnifiedLocationService
        if let unifiedService = unifiedLocationService as? UnifiedLocationService {
            unifiedService.addLocationDelegate(self)
        }
        
        LoggerService.shared.info("✅ SLCSService initialized with UnifiedLocationService", category: .location)
    }
    
    // MARK: - Significant Location Change Management
    
    /// Start monitoring significant location changes
    /// Uses UnifiedLocationService for battery-efficient monitoring
    public func start() {
        guard !isMonitoring else {
            LoggerService.shared.warning("⚠️ SLCSService already monitoring significant location changes", category: .location)
            return
        }
        
        guard type(of: unifiedLocationService).significantLocationChangeMonitoringAvailable() else {
            LoggerService.shared.error("❌ Significant location change monitoring not available on this device", category: .location)
            return
        }
        
        LoggerService.shared.info("🚀 Starting significant location change monitoring", category: .location)
        
        unifiedLocationService.startMonitoringSignificantLocationChanges()
        isMonitoring = true
        
        LoggerService.shared.info("✅ SLCSService monitoring started", category: .location)
    }
    
    /// Stop monitoring significant location changes
    public func stop() {
        guard isMonitoring else {
            LoggerService.shared.debug("🚾 SLCSService.stop() called but not currently monitoring", category: .location)
            return
        }
        
        LoggerService.shared.info("🛑 Stopping significant location change monitoring", category: .location)
        
        unifiedLocationService.stopMonitoringSignificantLocationChanges()
        isMonitoring = false
        
        LoggerService.shared.info("✅ SLCSService monitoring stopped", category: .location)
    }
    
    // MARK: - Service Status
    
    /// Check if service is currently monitoring
    public var isActive: Bool {
        return isMonitoring
    }
    
    /// Check if significant location change monitoring is available
    public static var isAvailable: Bool {
        return UnifiedLocationService.significantLocationChangeMonitoringAvailable()
    }
}

// MARK: - UnifiedLocationDelegate

extension SLCSService: UnifiedLocationDelegate {
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didUpdateLocations locations: [CLLocation]) {
        // Filter for significant location changes only
        // UnifiedLocationService will only send updates when significant changes are monitored
        guard isMonitoring else {
            LoggerService.shared.debug("⚠️ SLCSService received location update but not monitoring significant changes", category: .location)
            return
        }
        
        LoggerService.shared.info("📍 SIGNIFICANT location change detected", category: .location)
        
        if let location = locations.last {
            LoggerService.shared.debug("📍 Location: \(location.coordinate.latitude), \(location.coordinate.longitude) (accuracy: \(location.horizontalAccuracy)m)", category: .location)
        }
        
        delegate?.didTriggerSignificantChange()
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didFailWithError error: Error) {
        guard isMonitoring else { return }
        
        LoggerService.shared.error("❌ SLCSService location error", error: error, category: .location)
        
        // For significant location change errors, we might want to retry or notify the app
        // For now, just log the error
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didChangeAuthorization status: CLAuthorizationStatus) {
        let statusString: String
        switch status {
        case .notDetermined:
            statusString = "notDetermined"
        case .restricted:
            statusString = "restricted"
        case .denied:
            statusString = "denied"
            // Stop monitoring if permission is denied
            if isMonitoring {
                LoggerService.shared.warning("⚠️ Location permission denied - stopping SLCS monitoring", category: .location)
                stop()
            }
        case .authorizedAlways:
            statusString = "authorizedAlways"
        case .authorizedWhenInUse:
            statusString = "authorizedWhenInUse"
            LoggerService.shared.info("📍 SLCSService works best with Always authorization", category: .location)
        @unknown default:
            statusString = "unknown"
        }
        
        LoggerService.shared.info("🔐 SLCSService authorization changed: \(statusString)", category: .location)
    }
}
