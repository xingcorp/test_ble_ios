//
//  AppDelegate.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var services: AppServices!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize services with a default user ID (in production, get from login)
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "demo-user"
        services = CompositionRoot.build(
            baseURL: URL(string: "https://api.example.com")!,
            userId: userId
        )
        
        // Request permissions
        services.permissionManager.requestLocationPermission()
        services.permissionManager.requestNotificationPermission { granted in
            Logger.info("Notification permission: \(granted)")
        }
        
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
        
        // Start attendance monitoring
        services.coordinator.start(sites: testSites)
        
        Logger.info("App launched with \(testSites.count) sites")
        
        return true
    }

    // Background URLSession handoff from system to app
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Keep reference if needed; our BackgroundURLSessionClient uses shared delegate
        completionHandler()
    }
}

