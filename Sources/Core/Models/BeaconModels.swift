//
//  BeaconModels.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import CoreLocation

/// Model representing a beacon region
public struct BeaconRegion: Codable, Equatable {
    public let identifier: String
    public let uuid: UUID
    public let major: UInt16?
    public let minor: UInt16?
    public let notifyOnEntry: Bool
    public let notifyOnExit: Bool
    
    public init(
        identifier: String,
        uuid: UUID,
        major: UInt16? = nil,
        minor: UInt16? = nil,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = true
    ) {
        self.identifier = identifier
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.notifyOnEntry = notifyOnEntry
        self.notifyOnExit = notifyOnExit
    }
    
    /// Convert to CLBeaconRegion for CoreLocation
    public func toCLBeaconRegion() -> CLBeaconRegion {
        let region: CLBeaconRegion
        
        if let major = major, let minor = minor {
            region = CLBeaconRegion(
                uuid: uuid,
                major: major,
                minor: minor,
                identifier: identifier
            )
        } else if let major = major {
            region = CLBeaconRegion(
                uuid: uuid,
                major: major,
                identifier: identifier
            )
        } else {
            region = CLBeaconRegion(
                uuid: uuid,
                identifier: identifier
            )
        }
        
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        region.notifyEntryStateOnDisplay = true
        
        return region
    }
    
    /// Create from CLBeaconRegion
    public static func from(_ clRegion: CLBeaconRegion) -> BeaconRegion {
        return BeaconRegion(
            identifier: clRegion.identifier,
            uuid: clRegion.uuid,
            major: clRegion.major?.uint16Value,
            minor: clRegion.minor?.uint16Value,
            notifyOnEntry: clRegion.notifyOnEntry,
            notifyOnExit: clRegion.notifyOnExit
        )
    }
}
