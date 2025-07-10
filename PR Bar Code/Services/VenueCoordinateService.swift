//
//  VenueCoordinateService.swift
//  PR Bar Code
//
//  Created by Claude Code on 10/07/2025.
//

import Foundation
import CoreLocation

struct VenueCoordinateService {
    
    // Static coordinate data for common UK parkrun venues
    private static let venueCoordinates: [String: CLLocationCoordinate2D] = [
        // Hampshire/South Coast
        "Whiteley parkrun": CLLocationCoordinate2D(latitude: 50.8591, longitude: -1.2956),
        "Netley Abbey parkrun": CLLocationCoordinate2D(latitude: 50.8572, longitude: -1.3584),
        "Lee-on-the-Solent parkrun": CLLocationCoordinate2D(latitude: 50.8088, longitude: -1.2978),
        "Southampton parkrun": CLLocationCoordinate2D(latitude: 50.9097, longitude: -1.4044),
        "Eastleigh parkrun": CLLocationCoordinate2D(latitude: 50.9697, longitude: -1.3480),
        "Ganger Farm parkrun": CLLocationCoordinate2D(latitude: 50.8847, longitude: -1.2958),
        "Southsea parkrun": CLLocationCoordinate2D(latitude: 50.7859, longitude: -1.0875),
        
        // Wales
        "Cardiff parkrun": CLLocationCoordinate2D(latitude: 51.4816, longitude: -3.1791),
        "Roath parkrun": CLLocationCoordinate2D(latitude: 51.4925, longitude: -3.1569),
        
        // Lake District
        "Keswick parkrun": CLLocationCoordinate2D(latitude: 54.6014, longitude: -3.1348),
        "Windermere parkrun": CLLocationCoordinate2D(latitude: 54.3781, longitude: -2.9132),
        
        // Wiltshire
        "Lydiard parkrun": CLLocationCoordinate2D(latitude: 51.5689, longitude: -1.8114),
        
        // International
        "Crissy Field parkrun": CLLocationCoordinate2D(latitude: 37.8052, longitude: -122.4598), // San Francisco
        
        // London
        "Bushy parkrun": CLLocationCoordinate2D(latitude: 51.4108, longitude: -0.3340),
        "Richmond parkrun": CLLocationCoordinate2D(latitude: 51.4613, longitude: -0.2909),
        "Wimbledon Common parkrun": CLLocationCoordinate2D(latitude: 51.4360, longitude: -0.2288),
        "Regent's Park parkrun": CLLocationCoordinate2D(latitude: 51.5255, longitude: -0.1469),
        
        // Additional popular venues
        "Brighton & Hove parkrun": CLLocationCoordinate2D(latitude: 50.8429, longitude: -0.1313),
        "Oxford parkrun": CLLocationCoordinate2D(latitude: 51.7520, longitude: -1.2577),
        "Cambridge parkrun": CLLocationCoordinate2D(latitude: 52.2043, longitude: 0.1218),
        "Bath Skyline parkrun": CLLocationCoordinate2D(latitude: 51.3958, longitude: -2.3271),
        "Poole parkrun": CLLocationCoordinate2D(latitude: 50.7156, longitude: -1.9872),
        "Bournemouth parkrun": CLLocationCoordinate2D(latitude: 50.7192, longitude: -1.8808)
    ]
    
    static func coordinate(for venueName: String) -> CLLocationCoordinate2D? {
        // First try exact match
        if let coordinate = venueCoordinates[venueName] {
            return coordinate
        }
        
        // Try fuzzy matching for venues with slight name variations
        let normalizedInput = venueName.lowercased().replacingOccurrences(of: " parkrun", with: "")
        
        for (venueName, coordinate) in venueCoordinates {
            let normalizedVenue = venueName.lowercased().replacingOccurrences(of: " parkrun", with: "")
            if normalizedVenue.contains(normalizedInput) || normalizedInput.contains(normalizedVenue) {
                return coordinate
            }
        }
        
        return nil
    }
    
    static func hasCoordinate(for venueName: String) -> Bool {
        return coordinate(for: venueName) != nil
    }
    
    // Calculate center point for map region from multiple venues
    static func calculateMapRegion(for venues: [String]) -> (center: CLLocationCoordinate2D, span: (latitude: Double, longitude: Double))? {
        let coordinates = venues.compactMap { coordinate(for: $0) }
        
        guard !coordinates.isEmpty else { return nil }
        
        if coordinates.count == 1 {
            // Single venue - return location with default span
            return (center: coordinates[0], span: (latitude: 0.01, longitude: 0.01))
        }
        
        // Calculate bounding box
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = max(0.01, (maxLat - minLat) * 1.2) // Add 20% padding
        let spanLon = max(0.01, (maxLon - minLon) * 1.2)
        
        return (
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: (latitude: spanLat, longitude: spanLon)
        )
    }
    
    // Get default UK region for venues without coordinates
    static func defaultUKRegion() -> (center: CLLocationCoordinate2D, span: (latitude: Double, longitude: Double)) {
        // Center on UK with reasonable zoom
        return (
            center: CLLocationCoordinate2D(latitude: 52.3555, longitude: -1.1743), // UK center
            span: (latitude: 8.0, longitude: 8.0)
        )
    }
}