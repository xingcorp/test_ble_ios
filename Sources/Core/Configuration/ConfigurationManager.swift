//
//  ConfigurationManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public struct AppConfiguration: Codable {
    public let sites: [SiteConfiguration]
    public let heartbeatInterval: TimeInterval
    public let rangingDuration: TimeInterval
    public let softExitGracePeriod: TimeInterval
    public let telemetryEnabled: Bool
    public let debugMode: Bool
    
    public static let `default` = AppConfiguration(
        sites: [],
        heartbeatInterval: 60,
        rangingDuration: 8,
        softExitGracePeriod: 45,
        telemetryEnabled: true,
        debugMode: false
    )
}

public struct SiteConfiguration: Codable {
    public let id: String
    public let name: String
    public let uuid: String
    public let major: UInt16
    public let minor: UInt16?
    public let latitude: Double?
    public let longitude: Double?
    public let radius: Double?
    
    public func toSiteRegion() -> SiteRegion? {
        guard let uuid = UUID(uuidString: self.uuid) else { return nil }
        return SiteRegion(siteId: id, uuid: uuid, major: major)
    }
}

/// Manages app configuration with local and remote sources
public final class ConfigurationManager {
    
    public static let shared = ConfigurationManager()
    
    private let configKey = "app_configuration"
    private let store: KeyValueStore
    private var currentConfig: AppConfiguration
    
    private init() {
        self.store = UserDefaultsStore(prefix: "config")
        self.currentConfig = Self.loadLocalConfig() ?? .default
    }
    
    // MARK: - Public Methods
    
    public func getCurrentConfiguration() -> AppConfiguration {
        return currentConfig
    }
    
    public func updateConfiguration(_ config: AppConfiguration) {
        currentConfig = config
        saveConfiguration(config)
        
        Logger.info("Configuration updated with \(config.sites.count) sites")
        TelemetryManager.shared.track(
            .appLifecycle,
            metadata: [
                "event": "config_updated",
                "site_count": String(config.sites.count)
            ]
        )
    }
    
    public func fetchRemoteConfiguration(from url: URL, completion: @escaping (Result<AppConfiguration, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(ConfigurationError.noData))
                return
            }
            
            do {
                let config = try JSONDecoder().decode(AppConfiguration.self, from: data)
                self?.updateConfiguration(config)
                completion(.success(config))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private static func loadLocalConfig() -> AppConfiguration? {
        // Try to load from bundle first
        if let url = Bundle.main.url(forResource: "config", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) {
            return config
        }
        
        // Fall back to stored config
        let store = UserDefaultsStore(prefix: "config")
        if let data = store.get("app_configuration"),
           let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) {
            return config
        }
        
        return nil
    }
    
    private func saveConfiguration(_ config: AppConfiguration) {
        if let data = try? JSONEncoder().encode(config) {
            store.set(data, for: configKey)
        }
    }
}

enum ConfigurationError: LocalizedError {
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No configuration data received"
        }
    }
}
