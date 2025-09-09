//
//  KeyValueStore.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public protocol KeyValueStore {
    func set(_ value: Data, for key: String)
    func get(_ key: String) -> Data?
    func remove(_ key: String)
    func removeAll()
}

public final class UserDefaultsStore: KeyValueStore {
    private let ud = UserDefaults.standard
    private let prefix: String
    
    public init(prefix: String = "beacon.attendance") {
        self.prefix = prefix
    }
    
    private func prefixedKey(_ key: String) -> String {
        return "\(prefix).\(key)"
    }
    
    public func set(_ value: Data, for key: String) {
        ud.set(value, forKey: prefixedKey(key))
    }
    
    public func get(_ key: String) -> Data? {
        return ud.data(forKey: prefixedKey(key))
    }
    
    public func remove(_ key: String) {
        ud.removeObject(forKey: prefixedKey(key))
    }
    
    public func removeAll() {
        let dict = ud.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix(prefix) {
            ud.removeObject(forKey: key)
        }
    }
}
