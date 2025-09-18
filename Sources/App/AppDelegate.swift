//
//  AppDelegate.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import BeaconAttendanceCore
import BeaconAttendanceFeatures

#if canImport(UIKit)
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var services: AppServices!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize lifecycle manager
        _ = AppLifecycleManager.shared
        
        // CRITICAL: Check if app was launched due to location event while terminated
        let wasLaunchedByLocation = launchOptions?[.location] != nil
        if wasLaunchedByLocation {
            Logger.info("⚡️ App launched from TERMINATED state by location event!")
            // Track this critical event
            // TelemetryManager.shared.track(.coldStartFromRegion, severity: .info)
        }
        
        // Initialize services with a default user ID (in production, get from login)
        let userId = UserDefaults.standard.string(forKey: AppConstants.Storage.userIdKey) ?? "demo-user"
        
        // Register dependencies
        DependencyContainer.registerAppDependencies(userId: userId)
        
        // Build services
        services = CompositionRoot.build(
            baseURL: URL(string: AppConstants.API.baseURL)!,
            userId: userId
        )
        
        // Configure test sites (in production, load from server)
        let testSites = [
            SiteRegion(
                siteId: "HQ-Building-A",
                uuid: SiteRegion.defaultUUID,
                major: 100
            ),
            SiteRegion(
                siteId: "HQ-Building-B",
                uuid: SiteRegion.defaultUUID,
                major: 200
            )
        ]
        
        // CRITICAL: Start attendance monitoring immediately if launched by location
        if wasLaunchedByLocation {
            // Start monitoring immediately without waiting for UI
            services.coordinator.start(sites: testSites)
            
            // Request state for all regions to trigger immediate detection
            services.regionManager.regions.forEach { (_, region) in
                UnifiedLocationService.shared.requestState(for: region)
            }
            
            Logger.info("✅ Beacon monitoring restored from terminated state")
            
            // Show local notification to inform user
            services.notificationManager.showLocalNotification(
                title: "Attendance Active",
                body: "Monitoring your attendance in background",
                identifier: "background_launch"
            )
        } else {
            // Normal app launch - request permissions first
            services.permissionManager.requestLocationPermission()
            services.permissionManager.requestNotificationPermission { granted in
                Logger.info("Notification permission: \(granted)")
            }
            
            // Start attendance monitoring normally
            services.coordinator.start(sites: testSites)
        }
        
        Logger.info("App launched with \(testSites.count) sites (from location: \(wasLaunchedByLocation))")
        
        return true
    }

    // Background URLSession handoff from system to app
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Keep reference if needed; our BackgroundURLSessionClient uses shared delegate
        completionHandler()
    }
}

#else
// Platform not supported for UIKit - AppDelegate requires UIKit
#endif

