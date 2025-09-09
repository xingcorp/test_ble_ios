//
//  NotificationSink.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import UserNotifications

/// Handles attendance events by showing local notifications
public final class NotificationSink: AttendanceSink {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let dateFormatter: DateFormatter
    
    public init() {
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
    }
    
    public func handleCheckIn(sessionId: String, siteId: String, timestamp: Date) {
        let timeStr = dateFormatter.string(from: timestamp)
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Checked In"
        content.body = "Site: \(siteId)\nTime: \(timeStr)"
        content.sound = .default
        content.categoryIdentifier = "ATTENDANCE"
        content.userInfo = [
            "type": "check-in",
            "sessionId": sessionId,
            "siteId": siteId
        ]
        
        scheduleNotification(content: content, identifier: "checkin-\(sessionId)")
    }
    
    public func handleCheckOut(sessionId: String, siteId: String, timestamp: Date, reason: String) {
        let timeStr = dateFormatter.string(from: timestamp)
        
        let content = UNMutableNotificationContent()
        content.title = "👋 Checked Out"
        content.body = "Site: \(siteId)\nTime: \(timeStr)\nReason: \(reason)"
        content.sound = .default
        content.categoryIdentifier = "ATTENDANCE"
        content.userInfo = [
            "type": "check-out",
            "sessionId": sessionId,
            "siteId": siteId,
            "reason": reason
        ]
        
        scheduleNotification(content: content, identifier: "checkout-\(sessionId)")
    }
    
    public func handleHeartbeat(sessionId: String, siteId: String, timestamp: Date) {
        // Heartbeat notifications are optional - can be silent
        #if DEBUG
        let content = UNMutableNotificationContent()
        content.title = "💓 Heartbeat"
        content.body = "Still at \(siteId)"
        content.sound = nil // Silent in debug
        
        scheduleNotification(content: content, identifier: "heartbeat-\(sessionId)-\(timestamp.timeIntervalSince1970)")
        #endif
    }
    
    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule notification: \(error)")
            }
        }
    }
}
