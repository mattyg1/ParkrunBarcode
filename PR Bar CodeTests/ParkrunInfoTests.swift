//
//  ParkrunInfoTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
@testable import PR_Bar_Code

struct ParkrunInfoTests {
    
    @Test("ParkrunInfo initialization with required fields")
    func testParkrunInfoInitialization() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "John Doe",
            homeParkrun: "Southampton"
        )
        
        #expect(parkrunInfo.parkrunID == "A12345")
        #expect(parkrunInfo.name == "John Doe")
        #expect(parkrunInfo.homeParkrun == "Southampton")
        #expect(parkrunInfo.isDefault == false)
        #expect(parkrunInfo.country == nil)
        #expect(parkrunInfo.totalParkruns == nil)
        #expect(parkrunInfo.id == "A12345")
    }
    
    @Test("ParkrunInfo initialization with all fields")
    func testParkrunInfoFullInitialization() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A67890",
            name: "Jane Smith", 
            homeParkrun: "Portsmouth",
            country: Country.unitedKingdom.rawValue,
            totalParkruns: "25",
            lastParkrunDate: "14/06/2025",
            lastParkrunTime: "22:30",
            lastParkrunEvent: "Portsmouth parkrun",
            lastParkrunEventURL: "https://www.parkrun.org.uk/portsmouth/results/latest/",
            isDefault: true
        )
        
        #expect(parkrunInfo.parkrunID == "A67890")
        #expect(parkrunInfo.name == "Jane Smith")
        #expect(parkrunInfo.homeParkrun == "Portsmouth")
        #expect(parkrunInfo.country == Country.unitedKingdom.rawValue)
        #expect(parkrunInfo.totalParkruns == "25")
        #expect(parkrunInfo.lastParkrunDate == "14/06/2025")
        #expect(parkrunInfo.lastParkrunTime == "22:30")
        #expect(parkrunInfo.lastParkrunEvent == "Portsmouth parkrun")
        #expect(parkrunInfo.lastParkrunEventURL == "https://www.parkrun.org.uk/portsmouth/results/latest/")
        #expect(parkrunInfo.isDefault == true)
    }
    
    @Test("Display name generation with name")
    func testDisplayNameWithName() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "John Doe",
            homeParkrun: "Southampton"
        )
        
        #expect(parkrunInfo.displayName == "John Doe (A12345)")
    }
    
    @Test("Display name generation without name")
    func testDisplayNameWithoutName() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "",
            homeParkrun: "Southampton"
        )
        
        #expect(parkrunInfo.displayName == "A12345")
    }
    
    @Test("Update display name function")
    func testUpdateDisplayName() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "",
            homeParkrun: "Southampton"
        )
        
        // Initially should be just the ID
        #expect(parkrunInfo.displayName == "A12345")
        
        // Add a name and update
        parkrunInfo.name = "John Doe"
        parkrunInfo.updateDisplayName()
        
        #expect(parkrunInfo.displayName == "John Doe (A12345)")
        
        // Remove name and update
        parkrunInfo.name = ""
        parkrunInfo.updateDisplayName()
        
        #expect(parkrunInfo.displayName == "A12345")
    }
    
    @Test("Identifiable conformance")
    func testIdentifiableConformance() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "John Doe",
            homeParkrun: "Southampton"
        )
        
        #expect(parkrunInfo.id == parkrunInfo.parkrunID)
        #expect(parkrunInfo.id == "A12345")
    }
    
    @Test("Default values")
    func testDefaultValues() {
        let parkrunInfo = ParkrunInfo(
            parkrunID: "A12345",
            name: "John Doe",
            homeParkrun: "Southampton"
        )
        
        #expect(parkrunInfo.isDefault == false)
        #expect(parkrunInfo.country == nil)
        #expect(parkrunInfo.totalParkruns == nil)
        #expect(parkrunInfo.lastParkrunDate == nil)
        #expect(parkrunInfo.lastParkrunTime == nil)
        #expect(parkrunInfo.lastParkrunEvent == nil)
        #expect(parkrunInfo.lastParkrunEventURL == nil)
    }
}