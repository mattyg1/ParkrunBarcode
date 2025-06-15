//
//  SettingsTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 15/06/2025.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct SettingsTabView: View {
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var preferredColorScheme: ColorScheme?
    
    private var currentAppearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }
    
    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section {
                    notificationPermissionRow
                    
                    if notificationManager.hasPermission {
                        saturdayRemindersRow
                        resultUpdatesRow
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationManager.hasPermission {
                        Text("Saturday reminders will notify you before parkrun starts. Result updates will let you know when new results may be available.")
                    } else {
                        Text("Enable notifications to receive parkrun reminders and result updates.")
                    }
                }
                
                // Appearance Section
                Section {
                    appearanceModeRow
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how the app appears. System mode follows your device's appearance settings.")
                }
                
                // App Information Section
                Section {
                    appVersionRow
                    aboutRow
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            updateColorScheme()
        }
    }
    
    // MARK: - Notification Rows
    
    private var notificationPermissionRow: some View {
        HStack {
            Image(systemName: notificationManager.hasPermission ? "bell.fill" : "bell.slash")
                .foregroundColor(notificationManager.hasPermission ? .green : .red)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notification Permission")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(notificationManager.hasPermission ? "Enabled" : "Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notificationManager.hasPermission {
                Button("Enable") {
                    Task {
                        await notificationManager.requestNotificationPermission()
                        if notificationManager.hasPermission {
                            setupNotificationsForAllUsers()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var saturdayRemindersRow: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.adaptiveParkrunGreen)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Saturday Reminders")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Get reminded before parkrun starts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $notificationManager.isNotificationsEnabled)
                .labelsHidden()
                .onChange(of: notificationManager.isNotificationsEnabled) { oldValue, newValue in
                    // Save the setting
                    UserDefaults.standard.set(newValue, forKey: "isNotificationsEnabled")
                    
                    if newValue {
                        notificationManager.scheduleSaturdayReminders()
                        setupNotificationsForAllUsers()
                    } else {
                        notificationManager.cancelSaturdayReminders()
                    }
                }
        }
    }
    
    private var resultUpdatesRow: some View {
        HStack {
            Image(systemName: "bell.badge")
                .foregroundColor(.adaptiveParkrunGreen)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Result Updates")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Get notified when new results may be available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
    
    // MARK: - Appearance Rows
    
    private var appearanceModeRow: some View {
        HStack {
            Image(systemName: appearanceIcon)
                .foregroundColor(.adaptiveParkrunGreen)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("App Appearance")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(currentAppearanceMode.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                        setAppearanceMode(mode)
                    }) {
                        HStack {
                            Text(mode.rawValue)
                            if mode == currentAppearanceMode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(currentAppearanceMode.rawValue)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - App Info Rows
    
    private var appVersionRow: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.adaptiveParkrunGreen)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Version")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(appVersion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var aboutRow: some View {
        HStack {
            Image(systemName: "heart.circle")
                .foregroundColor(.adaptiveParkrunGreen)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("About 5K QR Code")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Generate QR codes and barcodes for parkrun")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var appearanceIcon: String {
        switch currentAppearanceMode {
        case .system:
            return systemColorScheme == .dark ? "circle.lefthalf.filled" : "circle.righthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    // MARK: - Functions
    
    private func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode.rawValue
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            preferredColorScheme = currentAppearanceMode.colorScheme
        }
    }
    
    private func setupNotificationsForAllUsers() {
        guard notificationManager.hasPermission else { return }
        
        if notificationManager.isNotificationsEnabled {
            // Schedule Saturday reminders
            notificationManager.scheduleSaturdayReminders()
            
            // Get all users from SwiftData and set up their result notifications
            Task {
                let descriptor = FetchDescriptor<ParkrunInfo>()
                if let users = try? modelContext.fetch(descriptor) {
                    for user in users {
                        if let lastDate = user.lastParkrunDate, !lastDate.isEmpty {
                            notificationManager.scheduleBackgroundResultCheck(
                                for: user.parkrunID,
                                lastKnownDate: lastDate
                            )
                        }
                    }
                }
                
                // Verify notifications were scheduled
                let pending = await notificationManager.getPendingNotifications()
                print("DEBUG: After setting up all notifications, found \(pending.count) pending notifications")
            }
        }
        
        print("DEBUG: Notifications set up for all users")
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(NotificationManager.shared)
}