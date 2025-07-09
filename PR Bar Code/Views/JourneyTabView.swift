//
//  JourneyTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 09/07/2025.
//

import SwiftUI
import SwiftData

struct JourneyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]
    
    // Get default user only
    private var defaultUser: ParkrunInfo? {
        if let defaultUser = parkrunInfoList.first(where: { $0.isDefault }) {
            return defaultUser
        }
        return parkrunInfoList.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = defaultUser {
                        // Journey visualizations without expand/collapse
                        ParkrunVisualizationsView(parkrunInfo: user)
                    } else {
                        // Empty state when no user data
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                Text("No Journey Data")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Set up your parkrun profile in the Me tab to view your journey visualizations and progress.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(40)
                    }
                }
                .padding()
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    do {
        let previewContainer = try ModelContainer(for: ParkrunInfo.self, configurations: ModelConfiguration())
        let context = previewContainer.mainContext
        
        // Insert sample data for preview
        let previewParkrunInfo = ParkrunInfo(
            parkrunID: "A79156",
            name: "Matt GARDNER", 
            homeParkrun: "Whiteley parkrun",
            country: 826,
            totalParkruns: "283",
            lastParkrunDate: "05/07/2025",
            lastParkrunTime: "24:24",
            lastParkrunEvent: "Whiteley parkrun",
            lastParkrunEventURL: "https://www.parkrun.org.uk/whiteley/results/331/"
        )
        context.insert(previewParkrunInfo)
        
        return JourneyTabView()
            .modelContainer(previewContainer)
    } catch {
        return Text("Failed to create preview: \(error)")
    }
}