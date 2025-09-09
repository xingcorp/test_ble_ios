//
//  AttendanceAPI.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public struct CheckInRequest: Encodable {
    public let userId: String
    public let siteId: String
    public let ts: Date
    public let sessionKey: String
    
    public init(userId: String, siteId: String, ts: Date, sessionKey: String) {
        self.userId = userId
        self.siteId = siteId
        self.ts = ts
        self.sessionKey = sessionKey
    }
}

public struct CheckOutRequest: Encodable {
    public let sessionKey: String
    public let ts: Date
    public let reason: String
    
    public init(sessionKey: String, ts: Date, reason: String) {
        self.sessionKey = sessionKey
        self.ts = ts
        self.reason = reason
    }
}

public struct HeartbeatRequest: Encodable {
    public let sessionKey: String
    public let ts: Date
    
    public init(sessionKey: String, ts: Date) {
        self.sessionKey = sessionKey
        self.ts = ts
    }
}

public protocol AttendanceAPIProtocol {
    func checkIn(_ req: CheckInRequest, idempotencyKey: String)
    func checkOut(_ req: CheckOutRequest, idempotencyKey: String)
    func heartbeat(_ req: HeartbeatRequest, idempotencyKey: String)
}

public final class AttendanceAPI: AttendanceAPIProtocol {
    private let baseURL: URL
    private let client: BackgroundURLSessionClient
    
    public init(baseURL: URL, client: BackgroundURLSessionClient = .shared) {
        self.baseURL = baseURL
        self.client = client
    }
    
    public func checkIn(_ req: CheckInRequest, idempotencyKey: String) {
        let url = baseURL.appendingPathComponent("/attendance/check-in")
        client.uploadJSON(req, to: url, headers: ["Idempotency-Key": idempotencyKey])
    }
    
    public func checkOut(_ req: CheckOutRequest, idempotencyKey: String) {
        let url = baseURL.appendingPathComponent("/attendance/check-out")
        client.uploadJSON(req, to: url, headers: ["Idempotency-Key": idempotencyKey])
    }
    
    public func heartbeat(_ req: HeartbeatRequest, idempotencyKey: String) {
        let url = baseURL.appendingPathComponent("/attendance/heartbeat")
        client.uploadJSON(req, to: url, headers: ["Idempotency-Key": idempotencyKey])
    }
}
