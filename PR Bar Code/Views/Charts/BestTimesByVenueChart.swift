//
//  BestTimesByVenueChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts

struct BestTimesByVenueChart: View {
    let venueStats: [VenueStats]
    @State private var selectedVenue: VenueStats?
    
    private var sortedByBestTime: [VenueStats] {
        venueStats
            .filter { !$0.bestTime.isEmpty && $0.bestTimeInMinutes > 0 }
            .sorted { $0.bestTimeInMinutes < $1.bestTimeInMinutes }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Best Times by Venue")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your personal best at each parkrun venue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Chart(sortedByBestTime, id: \.name) { venue in
                BarMark(
                    x: .value("Venue", venue.name),
                    y: .value("Best Time", venue.bestTimeInMinutes)
                )
                .foregroundStyle(colorForTime(venue.bestTimeInMinutes))
                .opacity(selectedVenue == nil || selectedVenue?.name == venue.name ? 1.0 : 0.5)
                .cornerRadius(4)
            }
            .frame(height: 320)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(anchor: .topTrailing) {
                        if let name = value.as(String.self) {
                            Text(name.replacingOccurrences(of: " parkrun", with: ""))
                                .font(.caption2)
                                .rotationEffect(.degrees(-45), anchor: .topTrailing)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let timeValue = value.as(Double.self) {
                            Text(formatTimeFromMinutes(timeValue))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            }
            .padding(.bottom, 20)
            .onTapGesture { location in
                // Simple selection toggle
                if selectedVenue != nil {
                    selectedVenue = nil
                } else if let firstVenue = sortedByBestTime.first {
                    selectedVenue = firstVenue
                }
            }
            
            // Performance tiers legend
            HStack(spacing: 20) {
                PerformanceTierIndicator(color: colorForTime(21.5), label: "Sub-22 min", description: "Best")
                PerformanceTierIndicator(color: colorForTime(22.5), label: "Sub-23 min", description: "Strong")
                PerformanceTierIndicator(color: colorForTime(24.0), label: "23+ min", description: "Steady")
            }
            .padding(.vertical, 8)
            
            // Selected venue details
            if let selectedVenue = selectedVenue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Venue Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Venue")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selectedVenue.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 2) {
                                Text("Personal Best")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selectedVenue.bestTime)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Total Runs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedVenue.runCount)")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let recentDate = selectedVenue.mostRecentDate {
                            HStack {
                                Text("Most recent visit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(recentDate)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Performance insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Venue Performance Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let fastest = sortedByBestTime.first {
                        InsightRow(text: "Fastest time achieved at \(fastest.name): \(fastest.bestTime)")
                    }
                    
                    let sub22Venues = sortedByBestTime.filter { $0.bestTimeInMinutes < 22.0 }
                    if !sub22Venues.isEmpty {
                        let venueNames = sub22Venues.map { $0.name.replacingOccurrences(of: " parkrun", with: "") }.joined(separator: ", ")
                        InsightRow(text: "Sub-22 minute times at \(sub22Venues.count) venues: \(venueNames)")
                    }
                    
                    if let slowest = sortedByBestTime.last {
                        InsightRow(text: "\(slowest.name) shows your slowest time (\(slowest.bestTime)), possibly a challenging course")
                    }
                    
                    // Find home venue performance
                    if let homeVenue = venueStats.max(by: { $0.runCount < $1.runCount }), !homeVenue.bestTime.isEmpty {
                        InsightRow(text: "Top venue (\(homeVenue.name)) best time: \(homeVenue.bestTime)")
                    }
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private func colorForTime(_ timeInMinutes: Double) -> Color {
        switch timeInMinutes {
        case ..<22.0:
            return Color(red: 0.4, green: 0.49, blue: 0.92) // Elite blue
        case 22.0..<23.0:
            return Color(red: 0.46, green: 0.29, blue: 0.64) // Strong purple
        default:
            return Color(red: 0.94, green: 0.58, blue: 0.98) // Steady pink
        }
    }
    
    private func formatTimeFromMinutes(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
}

struct PerformanceTierIndicator: View {
    let color: Color
    let label: String
    let description: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 16, height: 12)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let sampleStats = [
        VenueStats(name: "Lee-on-the-Solent", runCount: 18, bestTime: "21:03", bestTimeInMinutes: 21.05, percentage: 6.4, mostRecentDate: "15/03/2025"),
        VenueStats(name: "Southsea", runCount: 5, bestTime: "21:15", bestTimeInMinutes: 21.25, percentage: 1.8, mostRecentDate: "08/03/2025"),
        VenueStats(name: "Netley Abbey", runCount: 105, bestTime: "21:37", bestTimeInMinutes: 21.62, percentage: 37.1, mostRecentDate: "28/06/2025"),
        VenueStats(name: "Southampton", runCount: 8, bestTime: "21:48", bestTimeInMinutes: 21.80, percentage: 2.8, mostRecentDate: "10/05/2025"),
        VenueStats(name: "Whiteley", runCount: 107, bestTime: "22:38", bestTimeInMinutes: 22.63, percentage: 37.8, mostRecentDate: "05/07/2025"),
        VenueStats(name: "Eastleigh", runCount: 10, bestTime: "23:02", bestTimeInMinutes: 23.03, percentage: 3.5, mostRecentDate: "26/04/2025"),
        VenueStats(name: "Keswick", runCount: 1, bestTime: "27:39", bestTimeInMinutes: 27.65, percentage: 0.4, mostRecentDate: "21/06/2025")
    ]
    
    BestTimesByVenueChart(venueStats: sampleStats)
        .padding()
}