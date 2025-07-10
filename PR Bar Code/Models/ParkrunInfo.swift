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
    
    // Performance caching fields (excluded from persistence)
    @Transient private var cachedVenueStats: [VenueStats]?
    @Transient private var cachedRecentPerformanceData: [PerformanceData]?
    @Transient private var cachedAllYearsActivityData: [Int: [ActivityDay]]?
    @Transient private var cachedActivityData2025: [ActivityDay]?
    @Transient private var cachedAchievedMilestones: [ParkrunMilestone]?
    @Transient private var cacheTimestamp: Date?
    @Transient private var cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
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
    
    // MARK: - Cache Management
    
    private func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }
    
    private func updateCacheTimestamp() {
        cacheTimestamp = Date()
    }
    
    private func invalidateCache() {
        cachedVenueStats = nil
        cachedRecentPerformanceData = nil
        cachedAllYearsActivityData = nil
        cachedActivityData2025 = nil
        cachedAchievedMilestones = nil
        cacheTimestamp = nil
    }
    
    // MARK: - Computed Properties for Visualizations
    
    var totalParkrunsInt: Int {
        Int(totalParkruns ?? "0") ?? 0
    }
    
    var achievedMilestones: [ParkrunMilestone] {
        if let cached = cachedAchievedMilestones, isCacheValid() {
            return cached
        }
        
        let milestones = ParkrunVisualizationProcessor.checkMilestones(
            totalRuns: totalParkrunsInt,
            volunteerCount: volunteerCount,
            venueCount: uniqueVenuesCount
        )
        
        cachedAchievedMilestones = milestones
        updateCacheTimestamp()
        return milestones
    }
    
    var venueStats: [VenueStats] {
        if let cached = cachedVenueStats, isCacheValid() {
            return cached
        }
        
        let stats = ParkrunVisualizationProcessor.calculateVenueStats(from: venueRecords)
        cachedVenueStats = stats
        updateCacheTimestamp()
        return stats
    }
    
    var volunteerStats: [VolunteerStats] {
        // Note: Volunteer data typically returns empty due to parkrun access restrictions
        // Volunteer history requires authentication and is not available via public profile pages
        ParkrunVisualizationProcessor.calculateVolunteerStats(from: volunteerRecords)
    }
    
    var recentPerformanceData: [PerformanceData] {
        if let cached = cachedRecentPerformanceData, isCacheValid() {
            return cached
        }
        
        // Return all performance data for comprehensive timeline visualization
        let performanceData = venueRecords.map { PerformanceData(venueRecord: $0) }
        cachedRecentPerformanceData = performanceData
        updateCacheTimestamp()
        return performanceData
    }
    
    var activityData2025: [ActivityDay] {
        if let cached = cachedActivityData2025, isCacheValid() {
            return cached
        }
        
        let activityData = ParkrunVisualizationProcessor.calculateActivityDays(from: venueRecords, year: 2025)
        cachedActivityData2025 = activityData
        updateCacheTimestamp()
        return activityData
    }
    
    var allYearsActivityData: [Int: [ActivityDay]] {
        if let cached = cachedAllYearsActivityData, isCacheValid() {
            return cached
        }
        
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
        
        cachedAllYearsActivityData = yearlyData
        updateCacheTimestamp()
        return yearlyData
    }
    
    // MARK: - Data Management Methods
    
    func updateVisualizationData(venueRecords: [VenueRecord], volunteerRecords: [VolunteerRecord]) {
        // Invalidate cache when data changes
        invalidateCache()
        
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
        // Invalidate cache when data changes
        invalidateCache()
        
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
