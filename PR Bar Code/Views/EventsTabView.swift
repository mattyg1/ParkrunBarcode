//
//  EventsTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 15/06/2025.
//

import SwiftUI

struct EventsTabView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Coming Soon Icon
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundColor(.adaptiveParkrunGreen)
                
                // Coming Soon Text
                VStack(spacing: 12) {
                    Text("Coming Soon")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Event Discovery")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.adaptiveParkrunGreen)
                    
                    Text("We're working on exciting features to help you discover local parkrun events, view event information, and find new places to run.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Feature preview cards
                VStack(spacing: 16) {
                    FeaturePreviewCard(
                        icon: "location.magnifyingglass",
                        title: "Find Local Events",
                        description: "Discover parkrun events near you"
                    )
                    
                    FeaturePreviewCard(
                        icon: "info.circle",
                        title: "Event Details",
                        description: "View course maps, facilities, and more"
                    )
                    
                    FeaturePreviewCard(
                        icon: "magnifyingglass",
                        title: "Search Events",
                        description: "Search for specific parkrun locations"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                Spacer()
            }
            .navigationTitle("Events")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct FeaturePreviewCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.adaptiveParkrunGreen)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    EventsTabView()
}