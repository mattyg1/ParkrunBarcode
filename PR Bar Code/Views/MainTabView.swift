//
//  MainTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 15/06/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Me Tab - Default user only
            MeTabView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Me")
                }
                .tag(0)
            
            // Family & Friends Tab - All users with results table
            FamilyTabView()
                .tabItem {
                    Image(systemName: "person.2.circle")
                    Text("Family")
                }
                .tag(1)
            
            // Events Tab - Placeholder for future features
            EventsTabView()
                .tabItem {
                    Image(systemName: "calendar.circle")
                    Text("Events")
                }
                .tag(2)
            
            // Settings Tab - Notifications, dark mode, etc.
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gearshape.circle")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.adaptiveParkrunGreen)
    }
}

#Preview {
    do {
        let previewContainer = try ModelContainer(for: ParkrunInfo.self, configurations: ModelConfiguration())
        let context = previewContainer.mainContext
        
        // Insert sample data for preview
        let previewParkrunInfo = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton Parkrun", country: Country.unitedKingdom.rawValue, isDefault: true)
        context.insert(previewParkrunInfo)
        
        return MainTabView()
            .modelContainer(previewContainer)
            .environmentObject(NotificationManager.shared)
    } catch {
        return Text("Failed to create preview: \(error)")
    }
}