//
//  AppLifecycleManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

public protocol AppLifecycleObserver: AnyObject {
    func appDidBecomeActive()
    func appWillResignActive()
    func appDidEnterBackground()
    func appWillEnterForeground()
    func appWillTerminate()
}

/// Manages app lifecycle and notifies observers
public final class AppLifecycleManager {
    
    public static let shared = AppLifecycleManager()
    
    private var observers: [WeakObserver] = []
    private let queue = DispatchQueue(label: "lifecycle.manager.queue")
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Observer Management
    
    public func addObserver(_ observer: AppLifecycleObserver) {
        queue.async {
            self.observers.append(WeakObserver(observer))
            self.cleanupObservers()
        }
    }
    
    public func removeObserver(_ observer: AppLifecycleObserver) {
        queue.async {
            self.observers.removeAll { $0.observer === observer }
        }
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        #endif
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidBecomeActive() {
        Logger.info("App did become active")
        TelemetryManager.shared.track(.appLifecycle, metadata: ["state": "active"])
        
        notifyObservers { $0.appDidBecomeActive() }
    }
    
    @objc private func appWillResignActive() {
        Logger.info("App will resign active")
        TelemetryManager.shared.track(.appLifecycle, metadata: ["state": "inactive"])
        
        notifyObservers { $0.appWillResignActive() }
    }
    
    @objc private func appDidEnterBackground() {
        Logger.info("App did enter background")
        TelemetryManager.shared.track(.appLifecycle, metadata: ["state": "background"])
        
        notifyObservers { $0.appDidEnterBackground() }
    }
    
    @objc private func appWillEnterForeground() {
        Logger.info("App will enter foreground")
        TelemetryManager.shared.track(.appLifecycle, metadata: ["state": "foreground"])
        
        notifyObservers { $0.appWillEnterForeground() }
    }
    
    @objc private func appWillTerminate() {
        Logger.info("App will terminate")
        TelemetryManager.shared.track(.appLifecycle, severity: .warning, metadata: ["state": "terminate"])
        
        notifyObservers { $0.appWillTerminate() }
    }
    
    // MARK: - Helpers
    
    private func notifyObservers(_ block: @escaping (AppLifecycleObserver) -> Void) {
        queue.async {
            self.cleanupObservers()
            self.observers.forEach { weakObserver in
                if let observer = weakObserver.observer {
                    DispatchQueue.main.async {
                        block(observer)
                    }
                }
            }
        }
    }
    
    private func cleanupObservers() {
        observers.removeAll { $0.observer == nil }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Weak Observer Wrapper

private struct WeakObserver {
    weak var observer: AppLifecycleObserver?
    
    init(_ observer: AppLifecycleObserver) {
        self.observer = observer
    }
}
