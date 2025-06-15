//
//  NotificationManager.swift
//  PR Bar Code
//
//  Created by Claude Code on 13/06/2025.
//

import Foundation
import UserNotifications
import SwiftData
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    @Published var hasPermission = false
    
    private let userDefaults = UserDefaults.standard
    private let notificationsEnabledKey = "isNotificationsEnabled"
    
    private init() {
        loadPersistedSettings()
        checkNotificationPermission()
    }
    
    private func loadPersistedSettings() {
        isNotificationsEnabled = userDefaults.bool(forKey: notificationsEnabledKey)
    }
    
    private func saveSettings() {
        userDefaults.set(isNotificationsEnabled, forKey: notificationsEnabledKey)
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
                self.isNotificationsEnabled = granted
                self.saveSettings()
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
                // Only update isNotificationsEnabled if permission was revoked
                if settings.authorizationStatus != .authorized {
                    self.isNotificationsEnabled = false
                    self.saveSettings()
                }
            }
        }
    }
    
    // MARK: - Saturday Parkrun Reminders
    
    func scheduleSaturdayReminders() {
        guard hasPermission else { return }
        
        // Remove existing Saturday reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["saturday-reminder"])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "5K QR Code"
        content.body = "Don't forget your barcode! Parkrun starts soon. Have a great run! 🏃‍♂️"
        content.sound = .default
        content.badge = 1
        
        // Set up weekly Saturday trigger at 8:30 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday
        dateComponents.hour = 8
        dateComponents.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "saturday-reminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule Saturday reminder: \(error)")
            } else {
                print("Saturday parkrun reminder scheduled successfully")
            }
        }
    }
    
    // MARK: - Result Update Notifications
    
    func scheduleResultCheckNotification(for parkrunID: String, userName: String) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "5K QR Code"
        content.body = "Your latest parkrun results might be available! Tap to check your time."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["parkrunID": parkrunID, "type": "result-check"]
        
        // Schedule notification for Monday morning (results typically published Sunday evening)
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "result-check-\(parkrunID)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule result check notification: \(error)")
            } else {
                print("Result check notification scheduled for \(userName)")
            }
        }
    }
    
    func scheduleBackgroundResultCheck(for parkrunID: String, lastKnownDate: String) {
        // Schedule a notification to remind user to check for new results
        // This will trigger on Sunday evening when results are typically published
        guard hasPermission else {
            print("DEBUG: Cannot schedule result check - no permission")
            return
        }
        
        print("DEBUG: Scheduling result check for parkrun ID: \(parkrunID), last date: \(lastKnownDate)")
        
        let content = UNMutableNotificationContent()
        content.title = "5K QR Code"
        content.body = "New parkrun results may be available! Your last recorded run was on \(lastKnownDate)."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["parkrunID": parkrunID, "type": "background-check", "lastDate": lastKnownDate]
        
        // Schedule for Sunday at 7 PM (when results are typically published)
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "background-result-check-\(parkrunID)",
            content: content,
            trigger: trigger
        )
        
        // Remove any existing notifications for this parkrun ID first
        cancelResultNotifications(for: parkrunID)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Failed to schedule background result check: \(error)")
            } else {
                print("DEBUG: Background result check scheduled successfully for parkrun ID: \(parkrunID)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("DEBUG: All notifications cancelled")
    }
    
    func cancelSaturdayReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["saturday-reminder"])
        print("DEBUG: Saturday reminders cancelled")
    }
    
    func cancelResultNotifications(for parkrunID: String) {
        let identifiers = [
            "result-check-\(parkrunID)",
            "background-result-check-\(parkrunID)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("DEBUG: Result notifications cancelled for parkrun ID: \(parkrunID)")
    }
    
    // MARK: - Utility Functions
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("DEBUG: Found \(notifications.count) pending notifications")
        return notifications
    }
    
    func enableNotifications() {
        Task {
            let granted = await requestNotificationPermission()
            if granted {
                scheduleSaturdayReminders()
                // Get all pending notifications to verify
                let pending = await getPendingNotifications()
                print("DEBUG: After enabling notifications, found \(pending.count) pending notifications")
            }
        }
    }
    
    func disableNotifications() {
        isNotificationsEnabled = false
        saveSettings()
        cancelAllNotifications()
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Clear the badge count when notification is handled
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "result-check", "background-check":
                // Handle result check notification tap
                if let parkrunID = userInfo["parkrunID"] as? String {
                    // Post notification to refresh data in main app
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshParkrunData"),
                        object: parkrunID
                    )
                }
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
}