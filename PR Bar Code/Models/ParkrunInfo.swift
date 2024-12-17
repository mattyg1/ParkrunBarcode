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

    init(parkrunID: String, name: String = "", homeParkrun: String = "") {
        self.parkrunID = parkrunID
        self.name = name
        self.homeParkrun = homeParkrun
    }
}