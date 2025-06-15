//
//  CountryTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
@testable import FiveKQRCode

struct CountryTests {
    
    @Test("All countries have valid raw values")
    func testCountryRawValues() {
        let expectedCountries: [Country: Int] = [
            .australia: 3,
            .austria: 4,
            .canada: 14,
            .denmark: 23,
            .finland: 30,
            .france: 31,
            .germany: 32,
            .ireland: 42,
            .italy: 44,
            .japan: 46,
            .lithuania: 54,
            .malaysia: 57,
            .netherlands: 64,
            .newZealand: 65,
            .norway: 67,
            .poland: 74,
            .singapore: 82,
            .southAfrica: 85,
            .sweden: 88,
            .unitedKingdom: 97,
            .unitedStates: 98
        ]
        
        for (country, expectedValue) in expectedCountries {
            #expect(country.rawValue == expectedValue)
        }
    }
    
    @Test("Country names are correct")
    func testCountryNames() {
        #expect(Country.australia.name == "Australia")
        #expect(Country.unitedKingdom.name == "United Kingdom")
        #expect(Country.unitedStates.name == "United States")
        #expect(Country.newZealand.name == "New Zealand")
        #expect(Country.southAfrica.name == "South Africa")
        #expect(Country.germany.name == "Germany")
        #expect(Country.france.name == "France")
        #expect(Country.canada.name == "Canada")
    }
    
    @Test("Country website URLs are valid")
    func testCountryWebsiteURLs() {
        #expect(Country.unitedKingdom.websiteURL == "https://www.parkrun.org.uk")
        #expect(Country.australia.websiteURL == "https://www.parkrun.com.au")
        #expect(Country.unitedStates.websiteURL == "https://www.parkrun.us")
        #expect(Country.germany.websiteURL == "https://www.parkrun.de")
        #expect(Country.france.websiteURL == "https://www.parkrun.fr")
        #expect(Country.canada.websiteURL == "https://www.parkrun.ca")
        #expect(Country.newZealand.websiteURL == "https://www.parkrun.co.nz")
        #expect(Country.southAfrica.websiteURL == "https://www.parkrun.co.za")
    }
    
    @Test("All countries have HTTPS URLs")
    func testAllCountriesHaveHTTPS() {
        for country in Country.allCases {
            #expect(country.websiteURL.hasPrefix("https://"))
        }
    }
    
    @Test("All countries have parkrun domain")
    func testAllCountriesHaveParkrunDomain() {
        for country in Country.allCases {
            #expect(country.websiteURL.contains("parkrun"))
        }
    }
    
    @Test("Country case iterable")
    func testCountryCaseIterable() {
        let allCountries = Country.allCases
        
        // Ensure we have all expected countries
        #expect(allCountries.count == 21)
        
        // Test that all expected countries are present
        #expect(allCountries.contains(.australia))
        #expect(allCountries.contains(.unitedKingdom))
        #expect(allCountries.contains(.unitedStates))
        #expect(allCountries.contains(.germany))
        #expect(allCountries.contains(.france))
    }
    
    @Test("Country initialization from raw value")
    func testCountryFromRawValue() {
        #expect(Country(rawValue: 97) == .unitedKingdom)
        #expect(Country(rawValue: 3) == .australia)
        #expect(Country(rawValue: 98) == .unitedStates)
        #expect(Country(rawValue: 999) == nil) // Invalid raw value
        #expect(Country(rawValue: -1) == nil) // Invalid raw value
    }
    
    @Test("No duplicate raw values")
    func testNoDuplicateRawValues() {
        let allCountries = Country.allCases
        let rawValues = allCountries.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        
        #expect(rawValues.count == uniqueRawValues.count)
    }
    
    @Test("No duplicate country names")
    func testNoDuplicateNames() {
        let allCountries = Country.allCases
        let names = allCountries.map { $0.name }
        let uniqueNames = Set(names)
        
        #expect(names.count == uniqueNames.count)
    }
    
    @Test("No duplicate website URLs")
    func testNoDuplicateWebsiteURLs() {
        let allCountries = Country.allCases
        let urls = allCountries.map { $0.websiteURL }
        let uniqueURLs = Set(urls)
        
        #expect(urls.count == uniqueURLs.count)
    }
}