//
//  IdempotencyKeyProvider.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public protocol IdempotencyKeyProvider {
    func make(event: String, sessionKey: String, ts: Date) -> String
}

public final class DefaultIdempotencyKeyProvider: IdempotencyKeyProvider {
    public init() {}
    
    public func make(event: String, sessionKey: String, ts: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter.string(from: ts)
        return "\(event)#\(sessionKey)#\(stamp)"
    }
}
