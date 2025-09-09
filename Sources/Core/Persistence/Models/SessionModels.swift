//
//  SessionModels.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public struct LocalSession: Codable {
    public let sessionKey: String
    public let siteId: String
    public let userId: String
    public let start: Date
    public var end: Date?
    public var lastHeartbeat: Date?
    
    public init(sessionKey: String, siteId: String, userId: String, start: Date, end: Date? = nil, lastHeartbeat: Date? = nil) {
        self.sessionKey = sessionKey
        self.siteId = siteId
        self.userId = userId
        self.start = start
        self.end = end
        self.lastHeartbeat = lastHeartbeat
    }
}
