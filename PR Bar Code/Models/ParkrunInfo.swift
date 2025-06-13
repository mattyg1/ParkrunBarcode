//
//  ParkrunInfo.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 17/12/2024.
//


import SwiftUI
import SwiftData

@Model
class ParkrunInfo {
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
}
