//
//  CompositionRoot.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public final class CompositionRoot {
    public static func build(baseURL: URL, userId: String) -> AppServices {
        // Core components
        let regionMgr = BeaconRegionManager()
        let ranger = ShortRanger()
        let presence = PresenceStateMachine()
        let api = AttendanceAPI(baseURL: baseURL)
        let idem = DefaultIdempotencyKeyProvider()
        let slcs = SLCSService()
        let store = UserDefaultsStore()
        
        // Attendance components
        let sessionManager = SessionManager(store: store, userId: userId)
        let notificationSink = NotificationSink()
        let sink = CompositeSink(sinks: [notificationSink]) // Can add API sink later
        
        // Permission
        let permissionManager = PermissionManager()
        
        // Coordinator
        let coordinator = AttendanceCoordinator(
            regionManager: regionMgr,
            ranger: ranger,
            presenceStateMachine: presence,
            sessionManager: sessionManager,
            sink: sink,
            slcsService: slcs
        )
        
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
            sink: sink
        )
        
        return services
    }
}

public struct AppServices {
    public let region: BeaconRegionManager
    public let ranger: ShortRanger
    public let presence: PresenceStateMachine
    public let api: AttendanceAPI
    public let idem: IdempotencyKeyProvider
    public let slcs: SLCSService
    public let store: KeyValueStore
    public let coordinator: AttendanceCoordinator
    public let permissionManager: PermissionManager
    public let sessionManager: SessionManager
    public let sink: AttendanceSink
    
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
         sink: AttendanceSink) {
        self.region = region
        self.ranger = ranger
        self.presence = presence
        self.api = api
        self.idem = idem
        self.slcs = slcs
        self.store = store
        self.coordinator = coordinator
        self.permissionManager = permissionManager
        self.sessionManager = sessionManager
        self.sink = sink
    }
}
