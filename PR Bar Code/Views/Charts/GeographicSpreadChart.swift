//
//  GeographicSpreadChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts
import MapKit

struct GeographicSpreadChart: View {
    let venueStats: [VenueStats]
    @State private var selectedRegion: GeographicStats?
    @State private var showMapView = false
    @State private var selectedVenue: VenueStats?
    
    private var geographicStats: [GeographicStats] {
        ParkrunVisualizationProcessor.calculateGeographicStats(from: venueStats)
    }
    
    private var venuesWithCoordinates: [VenueStats] {
        venueStats.filter { $0.hasCoordinate }
    }
    
    private var mapRegion: MKCoordinateRegion {
        let venueNames = venuesWithCoordinates.map { $0.name }
        if let region = VenueCoordinateService.calculateMapRegion(for: venueNames) {
            return MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(
                    latitudeDelta: region.span.latitude,
                    longitudeDelta: region.span.longitude
                )
            )
        }
        
        // Fallback to UK region
        let ukRegion = VenueCoordinateService.defaultUKRegion()
        return MKCoordinateRegion(
            center: ukRegion.center,
            span: MKCoordinateSpan(
                latitudeDelta: ukRegion.span.latitude,
                longitudeDelta: ukRegion.span.longitude
            )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Geographic Spread")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Regions and countries you've explored")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Toggle between chart and map views
                if !venuesWithCoordinates.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMapView.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showMapView ? "chart.bar" : "map")
                                .font(.caption)
                            Text(showMapView ? "Chart" : "Map")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                }
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
                if showMapView && !venuesWithCoordinates.isEmpty {
                    // Map view
                    VenueMapView(
                        venues: venuesWithCoordinates,
                        selectedVenue: $selectedVenue,
                        region: mapRegion
                    )
                    .frame(height: 300)
                    .cornerRadius(8)
                } else {
                    // Chart with proper spacing for rotated labels
                    GeometryReader { geometry in
                        Chart(geographicStats, id: \.region) { stats in
                            BarMark(
                                x: .value("Region", stats.region),
                                y: .value("Venues", stats.venueCount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .opacity(selectedRegion == nil || selectedRegion?.region == stats.region ? 1.0 : 0.5)
                            .cornerRadius(4)
                        }
                        .chartXAxis { }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic) { value in
                                AxisValueLabel {
                                    if let venueCount = value.as(Int.self) {
                                        Text("\(venueCount)")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: 0...20)
                        .chartPlotStyle { plotArea in
                            plotArea
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .chartOverlay { proxy in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let location = value.location
                                            if let region: String = proxy.value(atX: location.x) {
                                                selectedRegion = geographicStats.first(where: { $0.region == region })
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedRegion = nil
                                        }
                                )
                        }
                        .chartBackground { proxy in
                            if let selectedRegion = selectedRegion {
                                let xPosition = proxy.position(forX: selectedRegion.region) ?? 0
                                let yPosition = proxy.position(forY: selectedRegion.venueCount) ?? 0

                                Text(selectedRegion.region)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.adaptiveCardBackground.opacity(0.8)))
                                    .shadow(radius: 2)
                                    .position(x: xPosition, y: yPosition - 20) // Position above the bar
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .frame(height: 300) // this includes space for rotated labels
                    .padding(.horizontal, 20)
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

struct VenueMapView: View {
    let venues: [VenueStats]
    @Binding var selectedVenue: VenueStats?
    let region: MKCoordinateRegion
    
    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: venues) { venue in
            MapAnnotation(coordinate: venue.coordinate ?? CLLocationCoordinate2D()) {
                VenueAnnotationView(venue: venue, isSelected: selectedVenue?.id == venue.id)
                    .onTapGesture {
                        selectedVenue = selectedVenue?.id == venue.id ? nil : venue
                    }
            }
        }
        .overlay(alignment: .topTrailing) {
            if let selectedVenue = selectedVenue {
                VenueCalloutView(venue: selectedVenue)
                    .padding()
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

struct VenueAnnotationView: View {
    let venue: VenueStats
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(venue.frequencyColor)
                .frame(width: annotationSize, height: annotationSize)
                .shadow(radius: 2)
            
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: annotationSize + 4, height: annotationSize + 4)
            }
            
            Text("\(venue.runCount)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var annotationSize: CGFloat {
        switch venue.runCount {
        case 50...: return 24
        case 20..<50: return 20
        case 10..<20: return 16
        case 5..<10: return 14
        default: return 12
        }
    }
}

struct VenueCalloutView: View {
    let venue: VenueStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(venue.name.replacingOccurrences(of: " parkrun", with: ""))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Text("\(venue.runCount) runs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("PB: \(venue.bestTime)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            if let mostRecentDate = venue.mostRecentDate {
                Text("Last: \(mostRecentDate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.adaptiveCardBackground.opacity(0.95))
        .cornerRadius(8)
        .shadow(radius: 4)
        .frame(maxWidth: 180)
    }
}

#Preview {
    let sampleStats = [
        VenueStats(name: "Whiteley parkrun", runCount: 107, bestTime: "22:38", bestTimeInMinutes: 22.63, percentage: 37.8, mostRecentDate: "05/07/2025", coordinate: VenueCoordinateService.coordinate(for: "Whiteley parkrun")),
        VenueStats(name: "Netley Abbey parkrun", runCount: 105, bestTime: "21:37", bestTimeInMinutes: 21.62, percentage: 37.1, mostRecentDate: "28/06/2025", coordinate: VenueCoordinateService.coordinate(for: "Netley Abbey parkrun")),
        VenueStats(name: "Lee-on-the-Solent parkrun", runCount: 18, bestTime: "21:03", bestTimeInMinutes: 21.05, percentage: 6.4, mostRecentDate: "15/03/2025", coordinate: VenueCoordinateService.coordinate(for: "Lee-on-the-Solent parkrun")),
        VenueStats(name: "Crissy Field parkrun", runCount: 2, bestTime: "24:15", bestTimeInMinutes: 24.25, percentage: 0.7, mostRecentDate: "01/04/2025", coordinate: VenueCoordinateService.coordinate(for: "Crissy Field parkrun")),
        VenueStats(name: "Cardiff parkrun", runCount: 1, bestTime: "21:48", bestTimeInMinutes: 21.80, percentage: 0.4, mostRecentDate: "08/03/2025", coordinate: VenueCoordinateService.coordinate(for: "Cardiff parkrun")),
        VenueStats(name: "Keswick parkrun", runCount: 1, bestTime: "27:39", bestTimeInMinutes: 27.65, percentage: 0.4, mostRecentDate: "21/06/2025", coordinate: VenueCoordinateService.coordinate(for: "Keswick parkrun"))
    ]
    
    let emptyStats: [VenueStats] = []
    
    VStack(spacing: 30) {
        GeographicSpreadChart(venueStats: sampleStats)
        
        Divider()
        
        GeographicSpreadChart(venueStats: emptyStats)
    }
    .padding()
}