//
//  PR_Bar_CodeApp.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 14/12/2024.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PR_Bar_CodeApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    private let notificationDelegate = NotificationDelegate()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                    clearBadgeIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    clearBadgeIfNeeded()
                }
        }
        .modelContainer(for: ParkrunInfo.self) // Attach SwiftData Model Container
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    private func clearBadgeIfNeeded() {
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
