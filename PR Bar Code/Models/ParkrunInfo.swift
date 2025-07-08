//
//  ParkrunInfo.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 17/12/2024.
//


import SwiftUI
import SwiftData

@Model
class ParkrunInfo: Identifiable {
    @Attribute(.unique) var parkrunID: String
    var name: String
    var homeParkrun: String
    var country: Int?
    var totalParkruns: String?
    var lastParkrunDate: String?
    var lastParkrunTime: String?
    var lastParkrunEvent: String?
    var lastParkrunEventURL: String?
    var isDefault: Bool = false // Default user loaded on app startup
    var displayName: String = "" // Computed display name for UI
    var createdDate: Date = Date()
    
    // Visualization data relationships
    @Relationship(deleteRule: .cascade) var venueRecords: [VenueRecord] = []
    @Relationship(deleteRule: .cascade) var volunteerRecords: [VolunteerRecord] = []
    @Relationship(deleteRule: .cascade) var annualPerformances: [AnnualPerformance] = []
    @Relationship(deleteRule: .cascade) var overallStats: OverallStats?
    
    // Additional fields for visualization insights
    var bestPersonalTime: String?
    var bestPersonalTimeVenue: String?
    var volunteerCount: Int = 0
    var uniqueVenuesCount: Int = 0
    var lastDataRefresh: Date?
    
    var id: String { parkrunID } // Identifiable conformance

    init(parkrunID: String, name: String, homeParkrun: String, country: Int? = nil, totalParkruns: String? = nil, lastParkrunDate: String? = nil, lastParkrunTime: String? = nil, lastParkrunEvent: String? = nil, lastParkrunEventURL: String? = nil, isDefault: Bool = false) {
        self.parkrunID = parkrunID
        self.name = name
        self.homeParkrun = homeParkrun
        self.country = country
        self.totalParkruns = totalParkruns
        self.lastParkrunDate = lastParkrunDate
        self.lastParkrunTime = lastParkrunTime
        self.lastParkrunEvent = lastParkrunEvent
        self.lastParkrunEventURL = lastParkrunEventURL
        self.isDefault = isDefault
        self.displayName = name.isEmpty ? parkrunID : "\(name) (\(parkrunID))"
        self.createdDate = Date()
    }
    
    // Update display name when name changes
    func updateDisplayName() {
        self.displayName = name.isEmpty ? parkrunID : "\(name) (\(parkrunID))"
    }
    
    // MARK: - Computed Properties for Visualizations
    
    var totalParkrunsInt: Int {
        Int(totalParkruns ?? "0") ?? 0
    }
    
    var achievedMilestones: [ParkrunMilestone] {
        ParkrunVisualizationProcessor.checkMilestones(
            totalRuns: totalParkrunsInt,
            volunteerCount: volunteerCount,
            venueCount: uniqueVenuesCount
        )
    }
    
    var venueStats: [VenueStats] {
        ParkrunVisualizationProcessor.calculateVenueStats(from: venueRecords)
    }
    
    var volunteerStats: [VolunteerStats] {
        // Note: Volunteer data typically returns empty due to parkrun access restrictions
        // Volunteer history requires authentication and is not available via public profile pages
        ParkrunVisualizationProcessor.calculateVolunteerStats(from: volunteerRecords)
    }
    
    var recentPerformanceData: [PerformanceData] {
        // Return all performance data for comprehensive timeline visualization
        return venueRecords.map { PerformanceData(venueRecord: $0) }
    }
    
    var activityData2025: [ActivityDay] {
        ParkrunVisualizationProcessor.calculateActivityDays(from: venueRecords, year: 2025)
    }
    
    var allYearsActivityData: [Int: [ActivityDay]] {
        // Get all years from venue records
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        let years = Set(venueRecords.compactMap { record in
            formatter.date(from: record.date)?.year
        })
        
        var yearlyData: [Int: [ActivityDay]] = [:]
        for year in years {
            yearlyData[year] = ParkrunVisualizationProcessor.calculateActivityDays(from: venueRecords, year: year)
        }
        
        return yearlyData
    }
    
    // MARK: - Data Management Methods
    
    func updateVisualizationData(venueRecords: [VenueRecord], volunteerRecords: [VolunteerRecord]) {
        self.venueRecords = venueRecords
        self.volunteerRecords = volunteerRecords
        self.volunteerCount = volunteerRecords.count
        self.uniqueVenuesCount = Set(venueRecords.map { $0.venue }).count
        
        // Update best personal time
        if let bestRecord = venueRecords.min(by: { $0.timeInMinutes < $1.timeInMinutes }) {
            self.bestPersonalTime = bestRecord.time
            self.bestPersonalTimeVenue = bestRecord.venue
        }
        
        self.lastDataRefresh = Date()
    }
    
    func updateCompleteVisualizationData(venueRecords: [VenueRecord], volunteerRecords: [VolunteerRecord], annualPerformances: [AnnualPerformance], overallStats: OverallStats?) {
        // Update all visualization data with comprehensive dataset
        self.venueRecords = venueRecords
        self.volunteerRecords = volunteerRecords
        self.annualPerformances = annualPerformances
        self.overallStats = overallStats
        
        // Update computed statistics
        self.volunteerCount = volunteerRecords.count
        self.uniqueVenuesCount = Set(venueRecords.map { $0.venue }).count
        
        // Update best personal time from comprehensive data
        if let bestRecord = venueRecords.min(by: { $0.timeInMinutes < $1.timeInMinutes }) {
            self.bestPersonalTime = bestRecord.time
            self.bestPersonalTimeVenue = bestRecord.venue
        }
        
        // Update home parkrun to most attended venue
        let venueGroups = Dictionary(grouping: venueRecords, by: { $0.venue })
        if let mostAttendedVenue = venueGroups.max(by: { $0.value.count < $1.value.count })?.key {
            self.homeParkrun = mostAttendedVenue
            print("DEBUG - ParkrunInfo: Updated home parkrun to most attended venue: \(mostAttendedVenue)")
        }
        
        self.lastDataRefresh = Date()
        print("DEBUG - ParkrunInfo: Updated complete visualization data - \(venueRecords.count) venues, \(annualPerformances.count) annual performances")
    }
}
