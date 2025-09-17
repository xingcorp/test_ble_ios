//
//  PermissionManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreLocation
import CoreBluetooth
import UserNotifications

public enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

public protocol PermissionManagerDelegate: AnyObject {
    func permissionManager(_ manager: PermissionManager, didUpdateLocationStatus: PermissionStatus)
    func permissionManager(_ manager: PermissionManager, didUpdateNotificationStatus: PermissionStatus)
    func permissionManager(_ manager: PermissionManager, didUpdateBluetoothStatus: PermissionStatus)
}

/// Manages all app permissions in a centralized way
public final class PermissionManager: NSObject {
    
    public weak var delegate: PermissionManagerDelegate?
    
    private let unifiedService = UnifiedLocationService.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private var bluetoothManager: CBCentralManager?
    private var bluetoothStatus: PermissionStatus = .notDetermined
    
    public override init() {
        super.init()
        // Register as delegate to UnifiedLocationService
        unifiedService.addLocationDelegate(self)
    }
    
    // MARK: - Location Permission
    
    public func requestLocationPermission() {
        let status = unifiedService.authorizationStatus
        
        switch status {
        case .notDetermined:
            // First request When In Use
            unifiedService.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Then upgrade to Always
            unifiedService.requestAlwaysAuthorization()
        case .authorizedAlways:
            Logger.info("Already have Always location permission")
            delegate?.permissionManager(self, didUpdateLocationStatus: .authorized)
        case .denied, .restricted:
            Logger.error("Location permission denied/restricted")
            delegate?.permissionManager(self, didUpdateLocationStatus: .denied)
            showLocationSettingsAlert()
        @unknown default:
            break
        }
    }
    
    public func checkLocationStatus() -> PermissionStatus {
        switch unifiedService.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse:
            return .authorized // But will request upgrade
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    // MARK: - Notification Permission
    
    public func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("Notification permission error: \(error)")
                    completion(false)
                } else {
                    Logger.info("Notification permission: \(granted ? "granted" : "denied")")
                    completion(granted)
                    
                    let status: PermissionStatus = granted ? .authorized : .denied
                    self.delegate?.permissionManager(self, didUpdateNotificationStatus: status)
                }
            }
        }
        
        // Register notification categories
        registerNotificationCategories()
    }
    
    public func checkNotificationStatus(completion: @escaping (PermissionStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status: PermissionStatus
                switch settings.authorizationStatus {
                case .notDetermined:
                    status = .notDetermined
                case .authorized, .provisional, .ephemeral:
                    status = .authorized
                case .denied:
                    status = .denied
                @unknown default:
                    status = .notDetermined
                }
                completion(status)
            }
        }
    }
    
    // MARK: - Bluetooth Permission
    
    public func checkBluetoothStatus() -> PermissionStatus {
        // Initialize bluetooth manager if needed to check status
        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
        return bluetoothStatus
    }
    
    private func updateBluetoothStatus(from state: CBManagerState) {
        switch state {
        case .poweredOn:
            bluetoothStatus = .authorized
        case .unauthorized:
            bluetoothStatus = .denied
        case .unsupported, .poweredOff:
            bluetoothStatus = .restricted
        case .unknown, .resetting:
            bluetoothStatus = .notDetermined
        @unknown default:
            bluetoothStatus = .notDetermined
        }
        
        delegate?.permissionManager(self, didUpdateBluetoothStatus: bluetoothStatus)
    }
    
    // MARK: - Background App Refresh
    
    public func checkBackgroundRefreshStatus() -> Bool {
        #if canImport(UIKit)
        return UIApplication.shared.backgroundRefreshStatus == .available
        #else
        return false
        #endif
    }
    
    // MARK: - Private Methods
    
    private func registerNotificationCategories() {
        let checkInAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "ATTENDANCE",
            actions: [checkInAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    private func showLocationSettingsAlert() {
        // In a real app, present an alert to guide user to Settings
        Logger.warn("User needs to enable Location in Settings")
    }
}

// MARK: - UnifiedLocationDelegate

extension PermissionManager: UnifiedLocationDelegate {
    public func unifiedLocationService(_ service: UnifiedLocationService, didUpdateLocations locations: [CLLocation]) {
        // Not needed for permission management
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didFailWithError error: Error) {
        // Not needed for permission management
    }
    
    public func unifiedLocationService(_ service: UnifiedLocationService, didChangeAuthorization status: CLAuthorizationStatus) {
        let permissionStatus: PermissionStatus
        
        switch status {
        case .notDetermined:
            permissionStatus = .notDetermined
        case .authorizedAlways:
            permissionStatus = .authorized
        case .authorizedWhenInUse:
            // Request upgrade to Always
            unifiedService.requestAlwaysAuthorization()
            permissionStatus = .authorized
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        @unknown default:
            permissionStatus = .notDetermined
        }
        
        delegate?.permissionManager(self, didUpdateLocationStatus: permissionStatus)
    }
}

// MARK: - CBCentralManagerDelegate

extension PermissionManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Logger.info("Bluetooth state updated: \(central.state.rawValue)")
        updateBluetoothStatus(from: central.state)
    }
}
