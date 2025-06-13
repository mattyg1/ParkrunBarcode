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

    init(parkrunID: String, name: String, homeParkrun: String, country: Int? = nil, totalParkruns: String? = nil, lastParkrunDate: String? = nil, lastParkrunTime: String? = nil, lastParkrunEvent: String? = nil) {
        self.parkrunID = parkrunID
        self.name = name
        self.homeParkrun = homeParkrun
        self.country = country
        self.totalParkruns = totalParkruns
        self.lastParkrunDate = lastParkrunDate
        self.lastParkrunTime = lastParkrunTime
        self.lastParkrunEvent = lastParkrunEvent
    }
}
