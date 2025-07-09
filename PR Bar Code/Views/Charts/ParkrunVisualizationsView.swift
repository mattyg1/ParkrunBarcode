//
//  ParkrunVisualizationsView.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI

struct ParkrunVisualizationsView: View {
    let parkrunInfo: ParkrunInfo
    @State private var selectedTab = 0
    
    private let tabs = [
        ("Overview", "chart.bar"),
        ("Venues", "location"),
        ("Performance", "stopwatch"),
        ("Activity", "calendar"),
        ("Volunteer", "hands.and.sparkles"),
        ("Geography", "globe")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if parkrunInfo.totalParkrunsInt > 0 {
                // Tab selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tabs.indices, id: \.self) { index in
                            TabButton(
                                title: tabs[index].0,
                                icon: tabs[index].1,
                                isSelected: selectedTab == index
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedTab = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12, corners: [.topLeft, .topRight])
                
                // Content
                ScrollView {
                    contentView
                        .padding()
                }
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No Visualization Data")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Complete your first parkrun or refresh your data to see detailed visualizations of your parkrun journey.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Refresh Data") {
                        // Trigger data refresh
                        refreshVisualizationData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12)
            }
        }
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case 0: // Overview
            ParkrunJourneyStatsView(parkrunInfo: parkrunInfo)
            
        case 1: // Venues
            VenueDistributionChart(venueStats: parkrunInfo.venueStats)
            
        case 2: // Performance
            VStack(spacing: 20) {
                PerformanceTimelineChart(performanceData: parkrunInfo.recentPerformanceData)
                BestTimesByVenueChart(venueStats: parkrunInfo.venueStats)
            }
            
        case 3: // Activity
            AllYearsActivityHeatmapView(allYearsData: parkrunInfo.allYearsActivityData, totalParkruns: parkrunInfo.totalParkrunsInt)
            
        case 4: // Volunteer
            VolunteerContributionChart(volunteerStats: parkrunInfo.volunteerStats)
            
        case 5: // Geography
            GeographicSpreadChart(venueStats: parkrunInfo.venueStats)
            
        default:
            EmptyView()
        }
    }
    
    private func refreshVisualizationData() {
        // This would trigger the data refresh in the parent view
        // For now, this is a placeholder
        print("Refreshing visualization data...")
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.adaptiveParkrunGreen : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// Custom corner radius modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            let sampleInfo = ParkrunInfo(
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
            
            ParkrunVisualizationsView(parkrunInfo: sampleInfo)
            
            // Empty state preview
            let emptyInfo = ParkrunInfo(parkrunID: "A12345", name: "Test User", homeParkrun: "", totalParkruns: "0")
            ParkrunVisualizationsView(parkrunInfo: emptyInfo)
        }
        .padding()
    }
}