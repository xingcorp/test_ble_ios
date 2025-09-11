//
//  DependencyContainer.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

/// Protocol for dependency registration and resolution
public protocol DependencyContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, name: String, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
    func resolve<T>(_ type: T.Type, name: String) -> T?
}

/// Singleton dependency container for the app
public final class DependencyContainer: DependencyContainerProtocol {
    
    public static let shared = DependencyContainer()
    
    private var factories: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    private let queue = DispatchQueue(label: "di.container.queue", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Registration
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, name: String(describing: type), factory: factory)
    }
    
    public func register<T>(_ type: T.Type, name: String, factory: @escaping () -> T) {
        let key = makeKey(type: type, name: name)
        queue.async(flags: .barrier) {
            self.factories[key] = factory
        }
    }
    
    public func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        registerSingleton(type, name: String(describing: type), factory: factory)
    }
    
    public func registerSingleton<T>(_ type: T.Type, name: String, factory: @escaping () -> T) {
        let key = makeKey(type: type, name: name)
        queue.async(flags: .barrier) {
            if self.singletons[key] == nil {
                self.singletons[key] = factory()
            }
        }
    }
    
    // MARK: - Resolution
    
    public func resolve<T>(_ type: T.Type) -> T? {
        resolve(type, name: String(describing: type))
    }
    
    public func resolve<T>(_ type: T.Type, name: String) -> T? {
        let key = makeKey(type: type, name: name)
        
        return queue.sync {
            // Check singletons first
            if let instance = singletons[key] as? T {
                return instance
            }
            
            // Check factories
            if let factory = factories[key] as? () -> T {
                return factory()
            }
            
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func makeKey<T>(type: T.Type, name: String) -> String {
        return "\(String(describing: type))_\(name)"
    }
    
    public func reset() {
        queue.async(flags: .barrier) {
            self.factories.removeAll()
            self.singletons.removeAll()
        }
    }
}

// MARK: - Convenience Extensions

public extension DependencyContainer {
    
    /// Register all app dependencies
    static func registerAppDependencies(userId: String) {
        let container = DependencyContainer.shared
        
        // Core Services
        container.registerSingleton(LoggerService.self) {
            LoggerService.shared
        }
        
        container.registerSingleton(BackgroundTaskService.self) {
            BackgroundTaskService.shared
        }
        
        container.registerSingleton(NotificationManager.self) {
            NotificationManager.shared
        }
        
        // Beacon Services
        container.registerSingleton(BeaconManagerProtocol.self) {
            BeaconManager()
        }
        
        // Attendance Services  
        container.registerSingleton(AttendanceServiceProtocol.self) {
            AttendanceService(userId: userId)
        }
        
        // Location Services
        container.registerSingleton(LocationManagerProtocol.self) {
            LocationManager.shared
        }
        
        // Permission Services
        container.registerSingleton(PermissionManager.self) {
            PermissionManager()
        }
    }
}
