//
//  Logger.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import os.log

public enum Logger {
    private static let subsystem = "com.attendance.beacon"
    private static let logger = OSLog(subsystem: subsystem, category: "General")
    
    public static func info(_ msg: String) {
        os_log(.info, log: logger, "%{public}@", msg)
        #if DEBUG
        print("ℹ️", msg)
        #endif
    }
    
    public static func warn(_ msg: String) {
        os_log(.default, log: logger, "%{public}@", msg)
        #if DEBUG
        print("⚠️", msg)
        #endif
    }
    
    public static func error(_ msg: String) {
        os_log(.error, log: logger, "%{public}@", msg)
        #if DEBUG
        print("🛑", msg)
        #endif
    }
}
