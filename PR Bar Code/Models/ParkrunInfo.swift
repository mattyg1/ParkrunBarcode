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

    init(parkrunID: String, name: String, homeParkrun: String, country: Int? = nil) {
        self.parkrunID = parkrunID
        self.name = name
        self.homeParkrun = homeParkrun
        self.country = country
    }
}
