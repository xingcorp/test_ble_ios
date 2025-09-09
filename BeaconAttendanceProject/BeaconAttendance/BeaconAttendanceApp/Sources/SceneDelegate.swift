//
//  SceneDelegate.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        window = UIWindow(windowScene: windowScene)
        
        // Create root view controller
        let mainViewController = AttendanceViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        // Configure navigation appearance
        navigationController.navigationBar.prefersLargeTitles = true
        
        // Set root and make visible
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is released by the system
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart any tasks that were paused when the scene was inactive
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from active to inactive state
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from background to foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save data, release shared resources
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}
