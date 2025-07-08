//
//  ParkrunVisualizationData.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import SwiftData
import Foundation

// MARK: - Core Data Structures

@Model
class VenueRecord {
    var venue: String
    var date: String
    var time: String
    var eventURL: String?
    var runNumber: Int?
    var position: Int?
    var ageGrading: Double?
    var isPB: Bool = false
    var parkrunInfo: ParkrunInfo?
    
    init(venue: String, date: String, time: String, eventURL: String? = nil, runNumber: Int? = nil, position: Int? = nil, ageGrading: Double? = nil, isPB: Bool = false) {
        self.venue = venue
        self.date = date
        self.time = time
        self.eventURL = eventURL
        self.runNumber = runNumber
        self.position = position
        self.ageGrading = ageGrading
        self.isPB = isPB
    }
    
    // Convert time string (MM:SS) to decimal minutes for calculations
    var timeInMinutes: Double {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return 0.0
        }
        return minutes + (seconds / 60.0)
    }
}

@Model
class VolunteerRecord {
    var role: String
    var venue: String
    var date: String
    var parkrunInfo: ParkrunInfo?
    
    init(role: String, venue: String, date: String) {
        self.role = role
        self.venue = venue
        self.date = date
    }
}

@Model
class AnnualPerformance {
    var year: Int
    var bestTime: String
    var bestAgeGrading: Double
    var totalRuns: Int
    var parkrunInfo: ParkrunInfo?
    
    init(year: Int, bestTime: String, bestAgeGrading: Double, totalRuns: Int = 0) {
        self.year = year
        self.bestTime = bestTime
        self.bestAgeGrading = bestAgeGrading
        self.totalRuns = totalRuns
    }
}

@Model
class OverallStats {
    var fastestTime: String
    var averageTime: String
    var slowestTime: String
    var bestAgeGrading: Double
    var averageAgeGrading: Double
    var worstAgeGrading: Double
    var bestPosition: Int
    var averagePosition: Double
    var worstPosition: Int
    var parkrunInfo: ParkrunInfo?
    
    init(fastestTime: String, averageTime: String, slowestTime: String, 
         bestAgeGrading: Double, averageAgeGrading: Double, worstAgeGrading: Double,
         bestPosition: Int, averagePosition: Double, worstPosition: Int) {
        self.fastestTime = fastestTime
        self.averageTime = averageTime
        self.slowestTime = slowestTime
        self.bestAgeGrading = bestAgeGrading
        self.averageAgeGrading = averageAgeGrading
        self.worstAgeGrading = worstAgeGrading
        self.bestPosition = bestPosition
        self.averagePosition = averagePosition
        self.worstPosition = worstPosition
    }
}

// MARK: - Computed Statistics Structures

struct VenueStats: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let runCount: Int
    let bestTime: String
    let bestTimeInMinutes: Double
    let percentage: Double
    let mostRecentDate: String?
    
    // Color coding based on frequency
    var frequencyColor: Color {
        switch percentage {
        case 30...: return Color(red: 0.4, green: 0.49, blue: 0.92) // Primary blue
        case 15..<30: return Color(red: 0.46, green: 0.29, blue: 0.64) // Purple
        case 5..<15: return Color(red: 0.94, green: 0.58, blue: 0.98) // Light purple
        case 2..<5: return Color(red: 0.96, green: 0.34, blue: 0.42) // Pink
        default: return Color(red: 0.31, green: 0.97, blue: 0.49) // Green
        }
    }
}

struct PerformanceData: Identifiable {
    let id = UUID()
    let date: String
    let timeInMinutes: Double
    let venue: String
    let formattedTime: String
    
    init(venueRecord: VenueRecord) {
        self.date = venueRecord.date
        self.timeInMinutes = venueRecord.timeInMinutes
        self.venue = venueRecord.venue
        self.formattedTime = venueRecord.time
    }
}

struct VolunteerStats: Identifiable {
    let id = UUID()
    let role: String
    let count: Int
    let venues: [String]
    let percentage: Double
    
    var color: Color {
        switch role {
        case "Pre-event Setup": return Color(red: 0.4, green: 0.49, blue: 0.92)
        case "Timekeeper": return Color(red: 0.46, green: 0.29, blue: 0.64)
        case "Marshal": return Color(red: 0.94, green: 0.58, blue: 0.98)
        default: return Color(red: 0.96, green: 0.34, blue: 0.42)
        }
    }
}

struct GeographicStats: Identifiable {
    let id = UUID()
    let region: String
    let venueCount: Int
    let totalRuns: Int
    let venues: [String]
}

struct ActivityDay: Identifiable {
    let id = UUID()
    let date: Date
    let hasRun: Bool
    let venue: String?
    let time: String?
}

// MARK: - Milestone and Achievement Structures

enum ParkrunMilestone: String, CaseIterable {
    case runs50 = "50 Club"
    case runs100 = "100 Club"  
    case runs250 = "250 Club"
    case runs500 = "500 Club"
    case volunteer25 = "25 Volunteer"
    case tourist10 = "10 Event Tourist"
    case tourist20 = "20 Event Tourist"
    
    var threshold: Int {
        switch self {
        case .runs50: return 50
        case .runs100: return 100
        case .runs250: return 250
        case .runs500: return 500
        case .volunteer25: return 25
        case .tourist10: return 10
        case .tourist20: return 20
        }
    }
    
    var icon: String {
        switch self {
        case .runs50, .runs100, .runs250, .runs500: return "figure.run"
        case .volunteer25: return "hands.and.sparkles"
        case .tourist10, .tourist20: return "location"
        }
    }
}

// MARK: - Visualization Data Processor

class ParkrunVisualizationProcessor: ObservableObject {
    
    static func calculateVenueStats(from records: [VenueRecord]) -> [VenueStats] {
        let venueGroups = Dictionary(grouping: records, by: { $0.venue })
        let totalRuns = records.count
        
        return venueGroups.compactMap { venue, runs in
            guard !runs.isEmpty else { return nil }
            
            let bestRun = runs.min(by: { $0.timeInMinutes < $1.timeInMinutes })
            let mostRecentRun = runs.max(by: { 
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                let date1 = formatter.date(from: $0.date) ?? Date.distantPast
                let date2 = formatter.date(from: $1.date) ?? Date.distantPast
                return date1 < date2
            })
            
            return VenueStats(
                name: venue,
                runCount: runs.count,
                bestTime: bestRun?.time ?? "00:00",
                bestTimeInMinutes: bestRun?.timeInMinutes ?? 0.0,
                percentage: Double(runs.count) / Double(totalRuns) * 100,
                mostRecentDate: mostRecentRun?.date
            )
        }.sorted { $0.runCount > $1.runCount }
    }
    
    static func calculateVolunteerStats(from records: [VolunteerRecord]) -> [VolunteerStats] {
        let roleGroups = Dictionary(grouping: records, by: { $0.role })
        let totalVolunteering = records.count
        
        return roleGroups.map { role, records in
            VolunteerStats(
                role: role,
                count: records.count,
                venues: Array(Set(records.map { $0.venue })),
                percentage: Double(records.count) / Double(totalVolunteering) * 100
            )
        }.sorted { $0.count > $1.count }
    }
    
    static func calculateGeographicStats(from venueStats: [VenueStats]) -> [GeographicStats] {
        var regions: [String: [VenueStats]] = [:]
        
        for venue in venueStats {
            let region = classifyVenueRegion(venue.name)
            if regions[region] == nil {
                regions[region] = []
            }
            regions[region]?.append(venue)
        }
        
        return regions.map { region, venues in
            GeographicStats(
                region: region,
                venueCount: venues.count,
                totalRuns: venues.reduce(0) { $0 + $1.runCount },
                venues: venues.map { $0.name }
            )
        }.sorted { $0.venueCount > $1.venueCount }
    }
    
    static func calculateActivityDays(from records: [VenueRecord], year: Int) -> [ActivityDay] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        // Create lookup for run dates
        let runLookup = Dictionary(grouping: records) { record in
            formatter.date(from: record.date)?.startOfDay
        }
        
        var days: [ActivityDay] = []
        var currentDate = startDate
        
        while currentDate < endDate {
            let runsOnDate = runLookup[currentDate.startOfDay] ?? []
            let hasRun = !runsOnDate.isEmpty
            
            days.append(ActivityDay(
                date: currentDate,
                hasRun: hasRun,
                venue: runsOnDate.first?.venue,
                time: runsOnDate.first?.time
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    static func checkMilestones(totalRuns: Int, volunteerCount: Int, venueCount: Int) -> [ParkrunMilestone] {
        var achieved: [ParkrunMilestone] = []
        
        // Running milestones
        if totalRuns >= 500 { achieved.append(.runs500) }
        else if totalRuns >= 250 { achieved.append(.runs250) }
        else if totalRuns >= 100 { achieved.append(.runs100) }
        else if totalRuns >= 50 { achieved.append(.runs50) }
        
        // Volunteer milestones
        if volunteerCount >= 25 { achieved.append(.volunteer25) }
        
        // Tourist milestones
        if venueCount >= 20 { achieved.append(.tourist20) }
        else if venueCount >= 10 { achieved.append(.tourist10) }
        
        return achieved
    }
    
    private static func classifyVenueRegion(_ venueName: String) -> String {
        let lowercased = venueName.lowercased()
        
        // International
        if lowercased.contains("crissy") || lowercased.contains("san francisco") {
            return "International"
        }
        
        // Wales
        if lowercased.contains("cardiff") {
            return "Wales"
        }
        
        // Lake District
        if lowercased.contains("keswick") {
            return "Lake District"
        }
        
        // Wiltshire
        if lowercased.contains("lydiard") {
            return "Wiltshire"
        }
        
        // Default to Hampshire/South Coast for most venues
        return "Hampshire/South Coast"
    }
}

// MARK: - Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}