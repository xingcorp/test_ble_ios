//
//  NotificationManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Manager for handling local and push notifications
public final class NotificationManager: NSObject {
    
    // MARK: - Singleton
    public static let shared = NotificationManager()
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationHandlers: [String: (UNNotificationResponse) -> Void] = [:]
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupCategories()
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                LoggerService.shared.error("Failed to request notification authorization", error: error)
            }
            
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Check notification authorization status
    public func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Categories Setup
    
    private func setupCategories() {
        // Attendance category
        let checkInAction = UNNotificationAction(
            identifier: "CHECK_IN",
            title: "Check In",
            options: [.foreground]
        )
        
        let checkOutAction = UNNotificationAction(
            identifier: "CHECK_OUT",
            title: "Check Out",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let attendanceCategory = UNNotificationCategory(
            identifier: "ATTENDANCE",
            actions: [checkInAction, checkOutAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Reminder category
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 5 min",
            options: []
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([attendanceCategory, reminderCategory])
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule a local notification
    public func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        categoryIdentifier: String? = nil,
        userInfo: [String: Any]? = nil,
        trigger: UNNotificationTrigger? = nil,
        handler: ((UNNotificationResponse) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        if let badge = badge {
            content.badge = badge
        }
        
        if let sound = sound {
            content.sound = sound
        }
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        if let handler = handler {
            notificationHandlers[identifier] = handler
        }
        
        notificationCenter.add(request) { error in
            if let error = error {
                LoggerService.shared.error("Failed to schedule notification", error: error)
            } else {
                LoggerService.shared.debug("Notification scheduled: \(identifier)")
            }
        }
    }
    
    /// Schedule attendance reminder
    public func scheduleAttendanceReminder(at date: Date, isCheckIn: Bool) {
        let identifier = isCheckIn ? "attendance.checkin" : "attendance.checkout"
        let title = isCheckIn ? "Check-In Reminder" : "Check-Out Reminder"
        let body = isCheckIn ? 
            "Don't forget to check in for attendance" : 
            "Don't forget to check out before leaving"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: false
        )
        
        scheduleNotification(
            identifier: identifier,
            title: title,
            body: body,
            categoryIdentifier: "ATTENDANCE",
            trigger: trigger
        )
    }
    
    /// Schedule beacon proximity notification
    public func notifyBeaconProximity(beaconId: String, isEntering: Bool) {
        let identifier = "beacon.\(beaconId).\(isEntering ? "enter" : "exit")"
        let title = isEntering ? "Beacon Detected" : "Beacon Lost"
        let body = isEntering ? 
            "You are near attendance beacon" : 
            "You have moved away from attendance beacon"
        
        scheduleNotification(
            identifier: identifier,
            title: title,
            body: body,
            sound: .default,
            categoryIdentifier: "ATTENDANCE",
            userInfo: ["beaconId": beaconId, "isEntering": isEntering]
        )
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel scheduled notification
    public func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationHandlers.removeValue(forKey: identifier)
        LoggerService.shared.debug("Notification cancelled: \(identifier)")
    }
    
    /// Cancel all notifications
    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationHandlers.removeAll()
        LoggerService.shared.debug("All notifications cancelled")
    }
    
    // MARK: - Badge Management
    
    /// Update app badge number
    public func updateBadge(count: Int) {
        DispatchQueue.main.async {
            #if canImport(UIKit)
            UIApplication.shared.applicationIconBadgeNumber = count
            #endif
        }
    }
    
    /// Clear app badge
    public func clearBadge() {
        updateBadge(count: 0)
    }
    
    // MARK: - Get Pending Notifications
    
    /// Get all pending notifications
    public func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        LoggerService.shared.debug("Will present notification: \(notification.request.identifier)")
        
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        LoggerService.shared.debug("Did receive notification response: \(response.notification.request.identifier)")
        
        // Handle custom actions
        switch response.actionIdentifier {
        case "CHECK_IN":
            handleCheckInAction(response: response)
        case "CHECK_OUT":
            handleCheckOutAction(response: response)
        case "SNOOZE":
            handleSnoozeAction(response: response)
        case UNNotificationDismissActionIdentifier:
            LoggerService.shared.debug("Notification dismissed")
        case UNNotificationDefaultActionIdentifier:
            // Handle tap on notification
            if let handler = notificationHandlers[response.notification.request.identifier] {
                handler(response)
            }
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    
    private func handleCheckInAction(response: UNNotificationResponse) {
        LoggerService.shared.info("Check-in action triggered from notification")
        // TODO: Implement check-in logic
    }
    
    private func handleCheckOutAction(response: UNNotificationResponse) {
        LoggerService.shared.info("Check-out action triggered from notification")
        // TODO: Implement check-out logic
    }
    
    private func handleSnoozeAction(response: UNNotificationResponse) {
        LoggerService.shared.info("Snooze action triggered")
        
        // Reschedule notification after 5 minutes
        let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: response.notification.request.identifier + ".snooze",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                LoggerService.shared.error("Failed to snooze notification", error: error)
            }
        }
    }
}
