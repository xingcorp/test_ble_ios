//
//  AppDelegate.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import UIKit
// Note: Uncomment these when adding packages in Xcode
// TODO: Add these when package is configured
// import BeaconAttendanceCore
// import BeaconAttendanceFeatures

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize core services
        setupCoreServices()
        
        // Configure appearance
        configureAppearance()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session
    }
    
    // MARK: - Background URLSession
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Handle background URL session events
        completionHandler()
    }
    
    // MARK: - Setup
    
    private func setupCoreServices() {
        // Note: This will be implemented when packages are connected
        // Example:
        // _ = AppLifecycleManager.shared
        // DependencyContainer.registerAppDependencies(userId: getUserId())
        
        // For now, just print
        print("📱 BeaconAttendance App Started")
        print("🔧 Core services would be initialized here")
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Set tint color
        UIView.appearance().tintColor = UIColor.systemBlue
    }
    
    private func getUserId() -> String {
        // Get or create user ID
        let key = "com.oxii.beacon.userId"
        if let userId = UserDefaults.standard.string(forKey: key) {
            return userId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: key)
            return newId
        }
    }
}
