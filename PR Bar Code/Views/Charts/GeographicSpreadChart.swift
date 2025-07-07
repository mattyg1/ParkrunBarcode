//
//  GeographicSpreadChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts

struct GeographicSpreadChart: View {
    let venueStats: [VenueStats]
    @State private var selectedRegion: GeographicStats?
    
    private var geographicStats: [GeographicStats] {
        ParkrunVisualizationProcessor.calculateGeographicStats(from: venueStats)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Geographic Spread")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Regions and countries you've explored")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if geographicStats.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "location")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No geographic data available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Geographic spread will appear here once venue data is available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                HStack(spacing: 20) {
                    // Radar chart (simplified as bar chart for better mobile display)
                    Chart(geographicStats, id: \.region) { stats in
                        BarMark(
                            x: .value("Region", stats.region),
                            y: .value("Venues", stats.venueCount)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .opacity(selectedRegion == nil || selectedRegion?.region == stats.region ? 1.0 : 0.5)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption2)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel {
                                if let venueCount = value.as(Int.self) {
                                    Text("\(venueCount)")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .onTapGesture { location in
                        // Simple selection toggle
                        if selectedRegion != nil {
                            selectedRegion = nil
                        } else if let firstRegion = geographicStats.first {
                            selectedRegion = firstRegion
                        }
                    }
                }
                
                // Region breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Regional Breakdown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(geographicStats, id: \.region) { stats in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stats.region)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("\(stats.venueCount) venues • \(stats.totalRuns) runs")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * progressRatio(for: stats), height: 4)
                                }
                            }
                            .frame(width: 60, height: 4)
                            
                            Text("\(stats.venueCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(width: 20, alignment: .trailing)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRegion = selectedRegion?.region == stats.region ? nil : stats
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Selected region details
                if let selectedRegion = selectedRegion {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Region Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Region")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(selectedRegion.region)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 2) {
                                    Text("Venues")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRegion.venueCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Total Runs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRegion.totalRuns)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Venues in this region:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(selectedRegion.venues.map { $0.replacingOccurrences(of: " parkrun", with: "") }.joined(separator: " • "))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Geographic insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("parkrun Tourism")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let primaryRegion = geographicStats.max(by: { $0.venueCount < $1.venueCount }) {
                            InsightRow(text: "Primary area: \(primaryRegion.region) (\(primaryRegion.venueCount) venues)")
                        }
                        
                        let internationalVenues = geographicStats.filter { $0.region.contains("International") }
                        if !internationalVenues.isEmpty {
                            let internationalVenueNames = internationalVenues.flatMap { $0.venues }.joined(separator: ", ")
                            InsightRow(text: "International experience: \(internationalVenueNames)")
                        }
                        
                        if let furthestUK = getFurthestUKVenue() {
                            InsightRow(text: "Furthest UK venue: \(furthestUK)")
                        }
                        
                        let nonPrimaryRegions = geographicStats.filter { $0.region != geographicStats.max(by: { $0.venueCount < $1.venueCount })?.region }
                        if !nonPrimaryRegions.isEmpty {
                            let regionNames = nonPrimaryRegions.map { $0.region }.joined(separator: ", ")
                            InsightRow(text: "Also visited: \(regionNames)")
                        }
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private func progressRatio(for stats: GeographicStats) -> Double {
        guard let maxVenues = geographicStats.max(by: { $0.venueCount < $1.venueCount })?.venueCount,
              maxVenues > 0 else { return 0 }
        return Double(stats.venueCount) / Double(maxVenues)
    }
    
    private func getFurthestUKVenue() -> String? {
        // Identify venues that are far from Hampshire/South Coast
        let distantVenues = ["Keswick parkrun", "Cardiff parkrun", "Lydiard parkrun"]
        return venueStats.first { venue in
            distantVenues.contains(venue.name)
        }?.name
    }
}

#Preview {
    let sampleStats = [
        VenueStats(name: "Whiteley parkrun", runCount: 107, bestTime: "22:38", bestTimeInMinutes: 22.63, percentage: 37.8, mostRecentDate: "05/07/2025"),
        VenueStats(name: "Netley Abbey parkrun", runCount: 105, bestTime: "21:37", bestTimeInMinutes: 21.62, percentage: 37.1, mostRecentDate: "28/06/2025"),
        VenueStats(name: "Lee-on-the-Solent parkrun", runCount: 18, bestTime: "21:03", bestTimeInMinutes: 21.05, percentage: 6.4, mostRecentDate: "15/03/2025"),
        VenueStats(name: "Crissy Field parkrun", runCount: 2, bestTime: "24:15", bestTimeInMinutes: 24.25, percentage: 0.7, mostRecentDate: "01/04/2025"),
        VenueStats(name: "Cardiff parkrun", runCount: 1, bestTime: "21:48", bestTimeInMinutes: 21.80, percentage: 0.4, mostRecentDate: "08/03/2025"),
        VenueStats(name: "Keswick parkrun", runCount: 1, bestTime: "27:39", bestTimeInMinutes: 27.65, percentage: 0.4, mostRecentDate: "21/06/2025")
    ]
    
    let emptyStats: [VenueStats] = []
    
    VStack(spacing: 30) {
        GeographicSpreadChart(venueStats: sampleStats)
        
        Divider()
        
        GeographicSpreadChart(venueStats: emptyStats)
    }
    .padding()
}