//
//  ParkrunVisualizationData.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import SwiftData
import Foundation
import CoreLocation


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
    let coordinate: CLLocationCoordinate2D?
    
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
    
    // Helper to check if venue has coordinate data
    var hasCoordinate: Bool {
        coordinate != nil
    }
    
    // Custom Hashable implementation since CLLocationCoordinate2D doesn't conform to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(runCount)
        hasher.combine(bestTime)
        hasher.combine(bestTimeInMinutes)
        hasher.combine(percentage)
        hasher.combine(mostRecentDate)
        if let coordinate = coordinate {
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
    }
    
    // Custom Equatable implementation
    static func == (lhs: VenueStats, rhs: VenueStats) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.runCount == rhs.runCount &&
        lhs.bestTime == rhs.bestTime &&
        lhs.bestTimeInMinutes == rhs.bestTimeInMinutes &&
        lhs.percentage == rhs.percentage &&
        lhs.mostRecentDate == rhs.mostRecentDate &&
        lhs.coordinate?.latitude == rhs.coordinate?.latitude &&
        lhs.coordinate?.longitude == rhs.coordinate?.longitude
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
    // Running milestones
    case runs25 = "25 Club"
    case runs50 = "50 Club"
    case runs100 = "100 Club"  
    case runs250 = "250 Club"
    case runs500 = "500 Club"
    case runs1000 = "1000 Club"
    
    // Volunteer milestones
    case volunteer10 = "v10"
    case volunteer25 = "v25"
    case volunteer50 = "v50"
    case volunteer100 = "v100"
    case volunteer250 = "v250"
    case volunteer500 = "v500"
    case volunteer1000 = "v1000"
    
    // Tourist milestones (different events)
    case tourist10 = "10 Events"
    case tourist25 = "25 Events"
    case tourist50 = "50 Events"
    
    var threshold: Int {
        switch self {
        case .runs25: return 25
        case .runs50: return 50
        case .runs100: return 100
        case .runs250: return 250
        case .runs500: return 500
        case .runs1000: return 1000
        case .volunteer10: return 10
        case .volunteer25: return 25
        case .volunteer50: return 50
        case .volunteer100: return 100
        case .volunteer250: return 250
        case .volunteer500: return 500
        case .volunteer1000: return 1000
        case .tourist10: return 10
        case .tourist25: return 25
        case .tourist50: return 50
        }
    }
    
    var icon: String {
        switch self {
        case .runs25, .runs50, .runs100, .runs250, .runs500, .runs1000: 
            return "figure.run"
        case .volunteer10, .volunteer25, .volunteer50, .volunteer100, .volunteer250, .volunteer500, .volunteer1000: 
            return "hands.and.sparkles"
        case .tourist10, .tourist25, .tourist50: 
            return "location"
        }
    }
    
    var category: String {
        switch self {
        case .runs25, .runs50, .runs100, .runs250, .runs500, .runs1000:
            return "Running"
        case .volunteer10, .volunteer25, .volunteer50, .volunteer100, .volunteer250, .volunteer500, .volunteer1000:
            return "Volunteering"
        case .tourist10, .tourist25, .tourist50:
            return "Tourism"
        }
    }
    
    var milestoneColor: Color {
        switch self.threshold {
        case 10:
            return .white
        case 25:
            return .purple
        case 50:
            return .red
        case 100:
            return .black
        case 250:
            return Color(.systemGreen).opacity(0.8) // Dark green
        case 500:
            return .blue
        case 1000:
            return Color(.systemIndigo) // Deep blue/indigo for 1000+
        default:
            return .gray
        }
    }
    
    var textColor: Color {
        switch self.threshold {
        case 10:
            return .black // Black text on white background
        case 100:
            return .white // White text on black background
        default:
            return .white // White text on colored backgrounds
        }
    }
}

// MARK: - Visualization Data Processor

class ParkrunVisualizationProcessor: ObservableObject {
    
    // MARK: - Static Caching
    private static var venueStatsCache: [String: [VenueStats]] = [:]
    private static var activityDaysCache: [String: [ActivityDay]] = [:]
    private static var cacheTimestamps: [String: Date] = [:]
    private static let cacheValidityDuration: TimeInterval = 600 // 10 minutes
    
    private static func isCacheValid(for key: String) -> Bool {
        guard let timestamp = cacheTimestamps[key] else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }
    
    private static func updateCacheTimestamp(for key: String) {
        cacheTimestamps[key] = Date()
    }
    
    static func calculateVenueStats(from records: [VenueRecord]) -> [VenueStats] {
        let cacheKey = "venueStats_\(records.count)_\(records.hashValue)"
        
        if let cached = venueStatsCache[cacheKey], isCacheValid(for: cacheKey) {
            return cached
        }
        
        let venueGroups = Dictionary(grouping: records, by: { $0.venue })
        let totalRuns = records.count
        
        let stats: [VenueStats] = venueGroups.compactMap { venue, runs in
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
                mostRecentDate: mostRecentRun?.date,
                coordinate: VenueCoordinateService.coordinate(for: venue)
            )
        }.sorted { ($0.runCount > $1.runCount) }
        
        venueStatsCache[cacheKey] = stats
        updateCacheTimestamp(for: cacheKey)
        return stats
    }
    
    // Clear venue stats cache (useful when coordinate data becomes available)
    static func clearVenueStatsCache() {
        venueStatsCache.removeAll()
        print("DEBUG - CACHE: Cleared venue stats cache")
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
        let cacheKey = "activityDays_\(year)_\(records.count)_\(records.hashValue)"
        
        if let cached = activityDaysCache[cacheKey], isCacheValid(for: cacheKey) {
            return cached
        }
        
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
        
        activityDaysCache[cacheKey] = days
        updateCacheTimestamp(for: cacheKey)
        return days
    }
    
    static func checkMilestones(totalRuns: Int, volunteerCount: Int, venueCount: Int) -> [ParkrunMilestone] {
        var achieved: [ParkrunMilestone] = []
        
        // Running milestones - add all achieved milestones
        if totalRuns >= 1000 { achieved.append(.runs1000) }
        if totalRuns >= 500 { achieved.append(.runs500) }
        if totalRuns >= 250 { achieved.append(.runs250) }
        if totalRuns >= 100 { achieved.append(.runs100) }
        if totalRuns >= 50 { achieved.append(.runs50) }
        if totalRuns >= 25 { achieved.append(.runs25) }
        
        // Volunteer milestones - add all achieved milestones
        // Note: Volunteer count is typically 0 due to parkrun access restrictions
        // These milestones may not be accurate without authenticated access
        if volunteerCount >= 1000 { achieved.append(.volunteer1000) }
        if volunteerCount >= 500 { achieved.append(.volunteer500) }
        if volunteerCount >= 250 { achieved.append(.volunteer250) }
        if volunteerCount >= 100 { achieved.append(.volunteer100) }
        if volunteerCount >= 50 { achieved.append(.volunteer50) }
        if volunteerCount >= 25 { achieved.append(.volunteer25) }
        if volunteerCount >= 10 { achieved.append(.volunteer10) }
        
        // Tourist milestones - add all achieved milestones
        if venueCount >= 50 { achieved.append(.tourist50) }
        if venueCount >= 25 { achieved.append(.tourist25) }
        if venueCount >= 10 { achieved.append(.tourist10) }
        
        return achieved
    }
    
    private static func classifyVenueRegion(_ venueName: String) -> String {
        // Try coordinate-based classification first
        if let coordinate = VenueCoordinateService.coordinate(for: venueName) {
            return classifyByCoordinate(coordinate)
        }
        
        // Fall back to enhanced pattern matching
        return classifyByName(venueName)
    }
    
    private static func classifyByCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // International (non-UK) - outside UK bounds
        if lat < 49.5 || lat > 61.0 || lon < -8.5 || lon > 2.0 {
            return classifyInternationalRegion(lat: lat, lon: lon)
        }
        
        // UK regions based on geographic boundaries
        
        // Scotland (roughly north of 55.0°N)
        if lat >= 55.0 {
            return "Scotland"
        }
        
        // Northern Ireland (roughly 54.0-55.5°N, 5.5-8.5°W)
        if lat >= 54.0 && lat <= 55.5 && lon >= -8.5 && lon <= -5.5 {
            return "Northern Ireland"
        }
        
        // Wales (roughly 51.3-53.5°N, 2.7-5.3°W)
        if lat >= 51.3 && lat <= 53.5 && lon >= -5.3 && lon <= -2.7 {
            return "Wales"
        }
        
        // England regions
        
        // North England (54.0-55.0°N)
        if lat >= 54.0 && lat < 55.0 {
            return "North England"
        }
        
        // Yorkshire & Humber (53.3-54.0°N)
        if lat >= 53.3 && lat < 54.0 {
            return "Yorkshire & Humber"
        }
        
        // Peak District / Derbyshire (53.0-53.6°N, 1.4-2.1°W)
        if lat >= 53.0 && lat <= 53.6 && lon >= -2.1 && lon <= -1.4 {
            return "Peak District"
        }
        
        // Lake District (54.2-54.8°N, 2.7-3.3°W)
        if lat >= 54.2 && lat <= 54.8 && lon >= -3.3 && lon <= -2.7 {
            return "Lake District"
        }
        
        // Midlands (52.0-53.3°N)
        if lat >= 52.0 && lat < 53.3 {
            if lon <= -1.5 {
                return "West Midlands"
            } else {
                return "East Midlands"
            }
        }
        
        // East England (52.0-53.0°N, east of 0°)
        if lat >= 52.0 && lat < 53.0 && lon >= 0.0 {
            return "East England"
        }
        
        // London area (51.3-51.7°N, 0.5°W-0.3°E)
        if lat >= 51.3 && lat <= 51.7 && lon >= -0.5 && lon <= 0.3 {
            return "London"
        }
        
        // South West England (50.0-51.5°N, west of -2.0°W)
        if lat >= 50.0 && lat <= 51.5 && lon <= -2.0 {
            return "South West England"
        }
        
        // Hampshire (most of Hampshire county)
        if lat >= 50.7 && lat <= 51.3 && lon >= -1.8 && lon <= -0.7 {
            return "Hampshire"
        }
        
        // Surrey (north of Hampshire)
        if lat >= 51.1 && lat <= 51.5 && lon >= -0.8 && lon <= 0.1 {
            return "Surrey"
        }
        
        // West Sussex (east of Hampshire, south of Surrey)
        if lat >= 50.7 && lat <= 51.2 && lon >= -0.7 && lon <= 0.2 {
            return "West Sussex"
        }
        
        // East Sussex & Kent (further east)
        if lat >= 50.5 && lat <= 51.5 && lon >= 0.0 && lon <= 1.5 {
            return "Kent & East Sussex"
        }
        
        // South Coast (coastal Dorset, Hampshire coast, Sussex coast)
        if lat >= 50.0 && lat < 50.9 {
            return "South Coast"
        }
        
        // Default fallback
        return "England"
    }
    
    private static func classifyInternationalRegion(lat: Double, lon: Double) -> String {
        // Europe
        if lat >= 35.0 && lat <= 72.0 && lon >= -25.0 && lon <= 45.0 {
            // Scandinavia
            if lat >= 55.0 && lon >= 4.0 && lon <= 32.0 {
                return "Scandinavia"
            }
            // Western Europe
            if lon >= -10.0 && lon <= 15.0 {
                return "Europe"
            }
            // Eastern Europe
            return "Eastern Europe"
        }
        
        // North America
        if lat >= 25.0 && lat <= 72.0 && lon >= -180.0 && lon <= -50.0 {
            // Canada
            if lat >= 45.0 {
                return "Canada"
            }
            // USA - more specific regions
            if lat >= 30.0 && lat <= 49.0 {
                // West Coast
                if lon <= -110.0 {
                    return "USA West Coast"
                }
                // East Coast
                if lon >= -85.0 {
                    return "USA East Coast"
                }
                // Central
                return "USA Central"
            }
            return "USA"
        }
        
        // Australia & New Zealand
        if lat >= -50.0 && lat <= -10.0 && lon >= 110.0 && lon <= 180.0 {
            if lat >= -30.0 {
                return "Australia"
            }
            return "New Zealand"
        }
        
        // South Africa
        if lat >= -35.0 && lat <= -22.0 && lon >= 16.0 && lon <= 33.0 {
            return "South Africa"
        }
        
        // Asia
        if lat >= -10.0 && lat <= 55.0 && lon >= 60.0 && lon <= 150.0 {
            return "Asia"
        }
        
        // Default international
        return "International"
    }
    
    private static func classifyByName(_ venueName: String) -> String {
        let lowercased = venueName.lowercased()
        
        // International patterns
        if lowercased.contains("usa") || lowercased.contains("america") || 
           lowercased.contains("california") || lowercased.contains("new york") ||
           lowercased.contains("san francisco") || lowercased.contains("crissy") {
            return "USA West Coast"
        }
        
        if lowercased.contains("canada") || lowercased.contains("toronto") || 
           lowercased.contains("vancouver") || lowercased.contains("montreal") {
            return "Canada"
        }
        
        if lowercased.contains("australia") || lowercased.contains("sydney") || 
           lowercased.contains("melbourne") || lowercased.contains("brisbane") {
            return "Australia"
        }
        
        if lowercased.contains("new zealand") || lowercased.contains("auckland") || 
           lowercased.contains("wellington") {
            return "New Zealand"
        }
        
        if lowercased.contains("south africa") || lowercased.contains("cape town") || 
           lowercased.contains("johannesburg") {
            return "South Africa"
        }
        
        // European patterns
        if lowercased.contains("ireland") || lowercased.contains("dublin") || 
           lowercased.contains("cork") {
            return "Ireland"
        }
        
        if lowercased.contains("france") || lowercased.contains("paris") || 
           lowercased.contains("lyon") {
            return "Europe"
        }
        
        if lowercased.contains("germany") || lowercased.contains("berlin") || 
           lowercased.contains("munich") {
            return "Europe"
        }
        
        if lowercased.contains("norway") || lowercased.contains("sweden") || 
           lowercased.contains("denmark") || lowercased.contains("finland") {
            return "Scandinavia"
        }
        
        // UK regions by name patterns
        if lowercased.contains("scotland") || lowercased.contains("edinburgh") || 
           lowercased.contains("glasgow") || lowercased.contains("aberdeen") {
            return "Scotland"
        }
        
        if lowercased.contains("wales") || lowercased.contains("cardiff") || 
           lowercased.contains("swansea") || lowercased.contains("newport") ||
           lowercased.contains("welsh") {
            return "Wales"
        }
        
        if lowercased.contains("belfast") || lowercased.contains("derry") || 
           lowercased.contains("northern ireland") {
            return "Northern Ireland"
        }
        
        // England regions by city/area patterns
        if lowercased.contains("london") || lowercased.contains("central") && lowercased.contains("london") {
            return "London"
        }
        
        if lowercased.contains("manchester") || lowercased.contains("liverpool") || 
           lowercased.contains("preston") || lowercased.contains("blackpool") ||
           lowercased.contains("lancashire") {
            return "North England"
        }
        
        if lowercased.contains("leeds") || lowercased.contains("sheffield") || 
           lowercased.contains("york") || lowercased.contains("hull") ||
           lowercased.contains("bradford") {
            return "Yorkshire & Humber"
        }
        
        if lowercased.contains("birmingham") || lowercased.contains("coventry") || 
           lowercased.contains("wolverhampton") || lowercased.contains("warwick") {
            return "West Midlands"
        }
        
        if lowercased.contains("nottingham") || lowercased.contains("leicester") || 
           lowercased.contains("derby") || lowercased.contains("lincoln") {
            return "East Midlands"
        }
        
        if lowercased.contains("keswick") || lowercased.contains("windermere") || 
           lowercased.contains("ambleside") || lowercased.contains("kendal") {
            return "Lake District"
        }
        
        if lowercased.contains("peak district") || lowercased.contains("buxton") || 
           lowercased.contains("matlock") {
            return "Peak District"
        }
        
        if lowercased.contains("bristol") || lowercased.contains("bath") || 
           lowercased.contains("exeter") || lowercased.contains("plymouth") ||
           lowercased.contains("cornwall") || lowercased.contains("devon") ||
           lowercased.contains("somerset") {
            return "South West England"
        }
        
        if lowercased.contains("norwich") || lowercased.contains("cambridge") || 
           lowercased.contains("ipswich") || lowercased.contains("norfolk") ||
           lowercased.contains("suffolk") {
            return "East England"
        }
        
        if lowercased.contains("canterbury") || lowercased.contains("maidstone") || 
           lowercased.contains("kent") || lowercased.contains("dover") ||
           lowercased.contains("tunbridge") {
            return "Kent & East Sussex"
        }
        
        if lowercased.contains("brighton") || lowercased.contains("eastbourne") || 
           lowercased.contains("hastings") || lowercased.contains("sussex") {
            return "Kent & East Sussex"
        }
        
        if lowercased.contains("southampton") || lowercased.contains("portsmouth") || 
           lowercased.contains("winchester") || lowercased.contains("hampshire") ||
           lowercased.contains("whiteley") || lowercased.contains("eastleigh") ||
           lowercased.contains("netley") || lowercased.contains("lee-on-the-solent") ||
           lowercased.contains("alton") || lowercased.contains("andover") ||
           lowercased.contains("basingstoke") || lowercased.contains("fareham") {
            return "Hampshire"
        }
        
        if lowercased.contains("guildford") || lowercased.contains("woking") || 
           lowercased.contains("surrey") || lowercased.contains("richmond") ||
           lowercased.contains("wimbledon") || lowercased.contains("epsom") ||
           lowercased.contains("kingston") || lowercased.contains("esher") {
            return "Surrey"
        }
        
        if lowercased.contains("crawley") || lowercased.contains("horsham") ||
           lowercased.contains("chichester") || lowercased.contains("worthing") ||
           lowercased.contains("west sussex") {
            return "West Sussex"
        }
        
        if lowercased.contains("bournemouth") || lowercased.contains("dorset") ||
           lowercased.contains("poole") || lowercased.contains("weymouth") {
            return "South Coast"
        }
        
        if lowercased.contains("lydiard") || lowercased.contains("swindon") || 
           lowercased.contains("wiltshire") {
            return "Wiltshire"
        }
        
        // Default to England for unmatched UK venues
        return "England"
    }
}

// MARK: - Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}