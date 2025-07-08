//
//  ParkrunStatsCards.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI

struct ParkrunStatsCards: View {
    let parkrunInfo: ParkrunInfo
    
    var body: some View {
        VStack(spacing: 12) {
            // Stats cards in 2x2 grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                StatCard(
                    title: "Total parkruns",
                    value: "\(parkrunInfo.totalParkrunsInt)",
                    icon: "figure.run",
                    color: .blue
                )
                
                StatCard(
                    title: "Best Time",
                    value: parkrunInfo.bestPersonalTime ?? "N/A",
                    icon: "stopwatch",
                    color: .green
                )
                
                StatCard(
                    title: "Venues Visited",
                    value: "\(parkrunInfo.uniqueVenuesCount)",
                    icon: "location",
                    color: .orange
                )
                
                StatCard(
                    title: "Volunteer Credits",
                    value: "\(parkrunInfo.volunteerCount)",
                    icon: "hands.and.sparkles",
                    color: .purple
                )
            }
            
            // Full-width achievement card
            if !parkrunInfo.achievedMilestones.isEmpty {
                MilestoneCard(milestones: parkrunInfo.achievedMilestones)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct MilestoneCard: View {
    let milestones: [ParkrunMilestone]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Group milestones by category for better organization
            let groupedMilestones = Dictionary(grouping: milestones) { $0.category }
            
            VStack(spacing: 8) {
                ForEach(["Running", "Volunteering", "Tourism"], id: \.self) { category in
                    if let categoryMilestones = groupedMilestones[category], !categoryMilestones.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 6) {
                                ForEach(categoryMilestones.sorted(by: { $0.threshold < $1.threshold }), id: \.rawValue) { milestone in
                                    CompactMilestoneBadge(milestone: milestone)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.92),
                    Color(red: 0.46, green: 0.29, blue: 0.64)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct MilestoneBadge: View {
    let milestone: ParkrunMilestone
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: milestone.icon)
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text(milestone.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }
}

struct CompactMilestoneBadge: View {
    let milestone: ParkrunMilestone
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: milestone.icon)
                .font(.caption2)
                .foregroundColor(.yellow)
            
            Text("\(milestone.threshold)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 40, height: 32)
        .background(Color.white.opacity(0.2))
        .cornerRadius(6)
    }
}

struct ParkrunJourneyStatsView: View {
    let parkrunInfo: ParkrunInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("parkrun Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let totalParkruns = parkrunInfo.totalParkruns, !totalParkruns.isEmpty {
                    Text("A comprehensive analysis of \(totalParkruns) parkruns across \(parkrunInfo.uniqueVenuesCount) different venues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Your parkrun statistics and achievements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ParkrunStatsCards(parkrunInfo: parkrunInfo)
            
            // Additional quick stats
            if parkrunInfo.totalParkrunsInt > 0 {
                VStack(spacing: 8) {
                    QuickStatRow(
                        icon: "house",
                        label: "Top Venue",
                        value: parkrunInfo.homeParkrun.isEmpty ? "Not set" : parkrunInfo.homeParkrun
                    )
                    
                    if let bestVenue = parkrunInfo.bestPersonalTimeVenue {
                        QuickStatRow(
                            icon: "trophy",
                            label: "Fastest Venue",
                            value: bestVenue
                        )
                    }
                    
                    if let lastRefresh = parkrunInfo.lastDataRefresh {
                        QuickStatRow(
                            icon: "clock",
                            label: "Last Updated",
                            value: RelativeDateTimeFormatter().localizedString(for: lastRefresh, relativeTo: Date())
                        )
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

struct QuickStatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.adaptiveParkrunGreen)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// Extension for GridItem to support column span
extension GridItem {
    static func span(_ count: Int) -> GridItem {
        GridItem(.flexible(), spacing: nil)
    }
}

// Custom modifier for grid column span
struct GridColumnSpan: ViewModifier {
    let span: Int
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func gridColumnSpan(_ span: Int) -> some View {
        self.modifier(GridColumnSpan(span: span))
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
            
            ParkrunJourneyStatsView(parkrunInfo: sampleInfo)
            
            Divider()
            
            ParkrunStatsCards(parkrunInfo: sampleInfo)
        }
        .padding()
    }
}