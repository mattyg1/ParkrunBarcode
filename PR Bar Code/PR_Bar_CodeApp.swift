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
                }
        }
        .modelContainer(for: ParkrunInfo.self) // Attach SwiftData Model Container
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
}
