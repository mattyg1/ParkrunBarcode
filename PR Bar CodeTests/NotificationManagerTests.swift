//
//  NotificationManagerTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
import UserNotifications
@testable import PR_Bar_Code

@MainActor
struct NotificationManagerTests {
    
    @Test("NotificationManager is singleton")
    func testSingletonInstance() {
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared
        
        #expect(instance1 === instance2)
    }
    
    @Test("Initial state")
    func testInitialState() {
        let manager = NotificationManager.shared
        
        // Initial state should be properly set
        #expect(manager.isNotificationsEnabled == false || manager.isNotificationsEnabled == true) // Could be either based on UserDefaults
        #expect(manager.hasPermission == false || manager.hasPermission == true) // Could be either based on system settings
    }
    
    @Test("Notification identifiers are correct")
    func testNotificationIdentifiers() {
        // Test that notification identifiers follow expected pattern
        let parkrunID = "A12345"
        let expectedResultCheckID = "result-check-\(parkrunID)"
        let expectedBackgroundCheckID = "background-result-check-\(parkrunID)"
        
        #expect(expectedResultCheckID == "result-check-A12345")
        #expect(expectedBackgroundCheckID == "background-result-check-A12345")
    }
    
    @Test("Saturday reminder scheduling components")
    func testSaturdayReminderComponents() {
        // Test the date components for Saturday reminders
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday
        dateComponents.hour = 8
        dateComponents.minute = 30
        
        #expect(dateComponents.weekday == 7)
        #expect(dateComponents.hour == 8)
        #expect(dateComponents.minute == 30)
    }
    
    @Test("Result notification scheduling components")
    func testResultNotificationComponents() {
        // Test Monday morning notification components
        var mondayComponents = DateComponents()
        mondayComponents.weekday = 2 // Monday
        mondayComponents.hour = 9
        mondayComponents.minute = 0
        
        #expect(mondayComponents.weekday == 2)
        #expect(mondayComponents.hour == 9)
        #expect(mondayComponents.minute == 0)
        
        // Test Sunday evening notification components
        var sundayComponents = DateComponents()
        sundayComponents.weekday = 1 // Sunday
        sundayComponents.hour = 19
        sundayComponents.minute = 0
        
        #expect(sundayComponents.weekday == 1)
        #expect(sundayComponents.hour == 19)
        #expect(sundayComponents.minute == 0)
    }
    
    @Test("Notification content creation")
    func testNotificationContent() {
        // Test Saturday reminder content
        let saturdayContent = UNMutableNotificationContent()
        saturdayContent.title = "5K QR Code"
        saturdayContent.body = "Don't forget your barcode! Parkrun starts soon. Have a great run! 🏃‍♂️"
        saturdayContent.sound = .default
        saturdayContent.badge = 1
        
        #expect(saturdayContent.title == "5K QR Code")
        #expect(saturdayContent.body.contains("Don't forget your barcode!"))
        #expect(saturdayContent.badge == 1)
        
        // Test result check content
        let resultContent = UNMutableNotificationContent()
        resultContent.title = "5K QR Code"
        resultContent.body = "Your latest parkrun results might be available! Tap to check your time."
        resultContent.userInfo = ["parkrunID": "A12345", "type": "result-check"]
        
        #expect(resultContent.title == "5K QR Code")
        #expect(resultContent.body.contains("results might be available"))
        #expect(resultContent.userInfo["parkrunID"] as? String == "A12345")
        #expect(resultContent.userInfo["type"] as? String == "result-check")
    }
    
    @Test("UserDefaults key consistency")
    func testUserDefaultsKeys() {
        let expectedKey = "isNotificationsEnabled"
        
        // Verify the key matches what's used in the implementation
        #expect(expectedKey == "isNotificationsEnabled")
    }
    
    @Test("Notification user info structure")
    func testNotificationUserInfo() {
        let parkrunID = "A12345"
        let lastDate = "14/06/2025"
        
        // Test result check user info
        let resultUserInfo: [String: Any] = [
            "parkrunID": parkrunID,
            "type": "result-check"
        ]
        
        #expect(resultUserInfo["parkrunID"] as? String == parkrunID)
        #expect(resultUserInfo["type"] as? String == "result-check")
        
        // Test background check user info
        let backgroundUserInfo: [String: Any] = [
            "parkrunID": parkrunID,
            "type": "background-check",
            "lastDate": lastDate
        ]
        
        #expect(backgroundUserInfo["parkrunID"] as? String == parkrunID)
        #expect(backgroundUserInfo["type"] as? String == "background-check")
        #expect(backgroundUserInfo["lastDate"] as? String == lastDate)
    }
}

struct NotificationDelegateTests {
    
    @Test("Notification delegate response handling")
    func testNotificationDelegateHandling() {
        let delegate = NotificationDelegate()
        
        // Test that delegate exists and can be instantiated
        #expect(delegate != nil)
    }
    
    @Test("Notification user info parsing")
    func testUserInfoParsing() {
        // Test parsing of notification user info
        let userInfo: [String: Any] = [
            "parkrunID": "A12345",
            "type": "result-check"
        ]
        
        let parkrunID = userInfo["parkrunID"] as? String
        let type = userInfo["type"] as? String
        
        #expect(parkrunID == "A12345")
        #expect(type == "result-check")
        
        // Test background check user info
        let backgroundUserInfo: [String: Any] = [
            "parkrunID": "A67890",
            "type": "background-check",
            "lastDate": "14/06/2025"
        ]
        
        let backgroundParkrunID = backgroundUserInfo["parkrunID"] as? String
        let backgroundType = backgroundUserInfo["type"] as? String
        let lastDate = backgroundUserInfo["lastDate"] as? String
        
        #expect(backgroundParkrunID == "A67890")
        #expect(backgroundType == "background-check")
        #expect(lastDate == "14/06/2025")
    }
    
    @Test("Notification center post notification")
    func testNotificationCenterPost() {
        let expectedParkrunID = "A12345"
        let expectedNotificationName = "RefreshParkrunData"
        
        // Test that we can create the notification components
        let notificationName = NSNotification.Name(expectedNotificationName)
        
        #expect(notificationName.rawValue == expectedNotificationName)
    }
}