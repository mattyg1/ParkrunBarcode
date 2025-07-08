//
//  VenueDistributionChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts

struct VenueDistributionChart: View {
    let venueStats: [VenueStats]
    @State private var selectedRunCount: Int?
    
    private var displayStats: [VenueStats] {
        // Show top 8 venues, group others
        let topVenues = Array(venueStats.prefix(8))
        let otherVenues = Array(venueStats.dropFirst(8))
        
        if !otherVenues.isEmpty {
            let otherCount = otherVenues.reduce(0) { $0 + $1.runCount }
            let otherPercentage = otherVenues.reduce(0) { $0 + $1.percentage }
            let otherStats = VenueStats(
                name: "Others (\(otherVenues.count) venues)",
                runCount: otherCount,
                bestTime: "",
                bestTimeInMinutes: 0,
                percentage: otherPercentage,
                mostRecentDate: nil
            )
            return topVenues + [otherStats]
        }
        return topVenues
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Venue Distribution")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Where you've run your parkruns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Donut Chart
                Chart(displayStats, id: \.name) { venue in
                    SectorMark(
                        angle: .value("Count", venue.runCount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(venue.frequencyColor)
                    .opacity(selectedRunCount == nil || selectedRunCount == venue.runCount ? 1.0 : 0.5)
                }
                .frame(height: 200)
                .chartAngleSelection(value: $selectedRunCount)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let selectedRunCount = selectedRunCount {
                            VStack {
                                Text("\(selectedRunCount)")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                                Text("runs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                        }
                    }
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayStats.prefix(6), id: \.name) { venue in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(venue.frequencyColor)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(venue.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                Text("\(venue.runCount) runs (\(venue.percentage, specifier: "%.1f")%)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    
                    if displayStats.count > 6 {
                        Text("+ \(displayStats.count - 6) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.adaptiveParkrunGreen)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let topVenue = venueStats.first {
                        InsightRow(text: "\(topVenue.name) is your home event with \(topVenue.runCount) runs (\(topVenue.percentage)% of total)")
                    }
                    
                    if venueStats.count >= 2 {
                        let secondVenue = venueStats[1]
                        InsightRow(text: "\(secondVenue.name) is your second most frequented venue with \(secondVenue.runCount) runs")
                    }
                    
                    if venueStats.count >= 3 {
                        let top3Percentage = venueStats.prefix(3).reduce(0) { $0 + $1.percentage }
                        InsightRow(text: "Top 3 venues account for \(top3Percentage)% of all runs")
                    }
                    
                    InsightRow(text: "You've experienced \(venueStats.count) different parkrun venues")
                }
            }
            .padding(12)
            .background(Color.adaptiveParkrunGreen.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct InsightRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("→")
                .font(.caption)
                .foregroundColor(.adaptiveParkrunGreen)
                .fontWeight(.medium)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    let sampleStats = [
        VenueStats(name: "Whiteley parkrun", runCount: 107, bestTime: "22:38", bestTimeInMinutes: 22.63, percentage: 37.8, mostRecentDate: "05/07/2025"),
        VenueStats(name: "Netley Abbey parkrun", runCount: 105, bestTime: "21:37", bestTimeInMinutes: 21.62, percentage: 37.1, mostRecentDate: "28/06/2025"),
        VenueStats(name: "Lee-on-the-Solent parkrun", runCount: 18, bestTime: "21:03", bestTimeInMinutes: 21.05, percentage: 6.4, mostRecentDate: "15/03/2025"),
        VenueStats(name: "Eastleigh parkrun", runCount: 10, bestTime: "23:02", bestTimeInMinutes: 23.03, percentage: 3.5, mostRecentDate: "10/05/2025"),
        VenueStats(name: "Portsmouth Lakeside parkrun", runCount: 9, bestTime: "22:97", bestTimeInMinutes: 22.97, percentage: 3.2, mostRecentDate: "26/04/2025")
    ]
    
    VenueDistributionChart(venueStats: sampleStats)
        .padding()
}