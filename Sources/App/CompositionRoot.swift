//
//  CompositionRoot.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import BeaconAttendanceCore
import BeaconAttendanceFeatures

public final class CompositionRoot {
    public static func build(baseURL: URL, userId: String) -> AppServices {
        
        // MARK: - Core Infrastructure (Single CLLocationManager)
        
        /// The single source of truth for all location operations
        let unifiedLocationService = UnifiedLocationService.shared
        
        LoggerService.shared.info("🏭 CompositionRoot: Building app services with unified location architecture", category: .location)
        
        // MARK: - Core Components with Dependency Injection
        
        /// Region manager using UnifiedLocationService
        let regionMgr = BeaconRegionManager(unifiedLocationService: unifiedLocationService)
        
        /// Time-boxed ranging using UnifiedLocationService
        let ranger = ShortRanger(unifiedLocationService: unifiedLocationService)
        
        /// Significant location change service using UnifiedLocationService
        let slcs = SLCSService(unifiedLocationService: unifiedLocationService)
        
        // MARK: - Business Logic Components
        
        let presence = PresenceStateMachine()
        let api = AttendanceAPI(baseURL: baseURL)
        let idem = DefaultIdempotencyKeyProvider()
        let store = UserDefaultsStore()
        
        LoggerService.shared.info("✅ Core location-dependent services initialized with UnifiedLocationService", category: .location)
        
        // Attendance components
        let sessionManager = SessionManager(store: store, userId: userId)
        let notificationSink = NotificationSink()
        let sink = CompositeSink(sinks: [notificationSink]) // Can add API sink later
        
        // Services
        let heartbeatService = HeartbeatService(configuration: .default)
        
        // Permission
        let permissionManager = PermissionManager()
        
        // Coordinator
        let coordinator = AttendanceCoordinator(
            regionManager: regionMgr,
            ranger: ranger,
            presenceStateMachine: presence,
            sessionManager: sessionManager,
            sink: sink,
            slcsService: slcs,
            heartbeatService: heartbeatService
        )
        
        // MARK: - Service Composition
        
        let services = AppServices(
            region: regionMgr,
            ranger: ranger,
            presence: presence,
            api: api,
            idem: idem,
            slcs: slcs,
            store: store,
            coordinator: coordinator,
            permissionManager: permissionManager,
            sessionManager: sessionManager,
            sink: sink,
            heartbeatService: heartbeatService,
            unifiedLocationService: unifiedLocationService
        )
        
        // MARK: - Service Validation
        
        LoggerService.shared.info("📊 CompositionRoot: Service composition complete", category: .location)
        LoggerService.shared.info("🛡️ CLLocationManager instances: 1 (UnifiedLocationService only)", category: .location)
        
        // Log service status
        unifiedLocationService.logStatus()
        
        return services
    }
}

/// App services container with unified location architecture
public struct AppServices {
    
    // MARK: - Core Infrastructure
    
    /// Single source of truth for all location operations
    public let unifiedLocationService: UnifiedLocationService
    
    // MARK: - Beacon Services
    
    /// Beacon region monitoring (uses UnifiedLocationService)
    public let region: BeaconRegionManager
    
    /// Time-boxed beacon ranging (uses UnifiedLocationService)
    public let ranger: ShortRanger
    
    /// Significant location change monitoring (uses UnifiedLocationService)
    public let slcs: SLCSService
    
    // MARK: - Business Logic
    
    /// Attendance state machine
    public let presence: PresenceStateMachine
    
    /// Main attendance coordinator
    public let coordinator: AttendanceCoordinator
    
    /// Session management
    public let sessionManager: SessionManager
    
    /// Attendance event sink
    public let sink: AttendanceSink
    
    // MARK: - Supporting Services
    
    /// Network API client
    public let api: AttendanceAPI
    
    /// Idempotency key provider
    public let idem: IdempotencyKeyProvider
    
    /// Local storage
    public let store: KeyValueStore
    
    /// Permission management
    public let permissionManager: PermissionManager
    
    /// Background heartbeat service
    public let heartbeatService: HeartbeatService
    
    // MARK: - Initialization
    
    init(region: BeaconRegionManager,
         ranger: ShortRanger,
         presence: PresenceStateMachine,
         api: AttendanceAPI,
         idem: IdempotencyKeyProvider,
         slcs: SLCSService,
         store: KeyValueStore,
         coordinator: AttendanceCoordinator,
         permissionManager: PermissionManager,
         sessionManager: SessionManager,
         sink: AttendanceSink,
         heartbeatService: HeartbeatService,
         unifiedLocationService: UnifiedLocationService) {
        
        // Core infrastructure
        self.unifiedLocationService = unifiedLocationService
        
        // Beacon services
        self.region = region
        self.ranger = ranger
        self.slcs = slcs
        
        // Business logic
        self.presence = presence
        self.coordinator = coordinator
        self.sessionManager = sessionManager
        self.sink = sink
        
        // Supporting services
        self.api = api
        self.idem = idem
        self.store = store
        self.permissionManager = permissionManager
        self.heartbeatService = heartbeatService
    }
}
