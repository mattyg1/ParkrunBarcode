//
//  VenueCoordinateService.swift
//  PR Bar Code
//
//  Created by Claude Code on 10/07/2025.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let coordinatesLoaded = Notification.Name("coordinatesLoaded")
}

struct VenueCoordinateService {
    
    // MARK: - Models for parsing events.json
    private struct EventsData: Codable {
        let events: EventsCollection
    }
    
    private struct EventsCollection: Codable {
        let features: [EventFeature]
    }
    
    private struct EventFeature: Codable {
        let geometry: EventGeometry
        let properties: EventProperties
    }
    
    private struct EventGeometry: Codable {
        let coordinates: [Double] // [longitude, latitude]
    }
    
    private struct EventProperties: Codable {
        let eventname: String
        let EventLongName: String
        let EventShortName: String
    }
    
    // MARK: - Cached events data
    private static var cachedEventsData: [String: CLLocationCoordinate2D]?
    private static var geocodedCoordinates: [String: CLLocationCoordinate2D] = [:]
    private static var lastLoadTime: Date?
    private static let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    private static let parkrunEventsURL = "https://images.parkrun.com/events.json"
    
    // MARK: - Public API
    static func coordinate(for venueName: String) -> CLLocationCoordinate2D? {
        // Load events data if not cached or expired
        loadEventsDataIfNeeded()
        
        guard let eventsData = cachedEventsData else {
            print("DEBUG - COORDINATES: Events data not available, falling back to hardcoded coordinates")
            return fallbackCoordinate(for: venueName)
        }
        
        // Try exact match first
        if let coordinate = eventsData[venueName] {
            return coordinate
        }
        
        // Try fuzzy matching for venues with slight name variations
        let normalizedInput = venueName.lowercased()
            .replacingOccurrences(of: " parkrun", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        for (eventName, coordinate) in eventsData {
            let normalizedEvent = eventName.lowercased()
                .replacingOccurrences(of: " parkrun", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if names match closely
            if normalizedEvent.contains(normalizedInput) || 
               normalizedInput.contains(normalizedEvent) ||
               levenshteinDistance(normalizedInput, normalizedEvent) <= 2 {
                print("DEBUG - COORDINATES: Found fuzzy match '\(eventName)' for '\(venueName)'")
                return coordinate
            }
        }
        
        print("DEBUG - COORDINATES: No match found for '\(venueName)' in events.json, trying fallback")
        
        // Try hardcoded fallback first
        if let fallback = fallbackCoordinate(for: venueName) {
            return fallback
        }
        
        // Check if we've already geocoded this venue
        if let geocoded = geocodedCoordinates[venueName] {
            return geocoded
        }
        
        // For inactive venues, try geocoding as last resort
        geocodeVenue(venueName)
        return nil // Geocoding is async, will be available on next call
    }
    
    static func hasCoordinate(for venueName: String) -> Bool {
        return coordinate(for: venueName) != nil
    }
    
    // MARK: - Data loading
    private static var isLoading = false
    
    private static func loadEventsDataIfNeeded() {
        // Check if we need to reload data
        if let lastLoad = lastLoadTime,
           let cached = cachedEventsData,
           Date().timeIntervalSince(lastLoad) < cacheExpiryInterval {
            return // Use cached data
        }
        
        // Prevent multiple simultaneous loads
        if isLoading {
            return
        }
        
        isLoading = true
        print("DEBUG - COORDINATES: Loading events data...")
        
        // Try to load from network first (fresh data)
        loadFromNetwork { success in
            if !success {
                // Fall back to bundled JSON
                print("DEBUG - COORDINATES: Network failed, trying bundled events.json")
                loadFromBundle()
            }
            isLoading = false
        }
    }
    
    private static func loadFromNetwork(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: parkrunEventsURL) else {
            print("DEBUG - COORDINATES: Invalid parkrun events URL")
            completion(false)
            return
        }
        
        print("DEBUG - COORDINATES: Fetching fresh data from \(parkrunEventsURL)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0 // 5 second timeout
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG - COORDINATES: Network request failed: \(error)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("DEBUG - COORDINATES: No data received from network")
                completion(false)
                return
            }
            
            do {
                let coordinateMap = try parseEventsData(data)
                
                DispatchQueue.main.async {
                    cachedEventsData = coordinateMap
                    lastLoadTime = Date()
                    print("DEBUG - COORDINATES: Loaded \(coordinateMap.count) venue coordinates from network")
                    
                    // Post notification that coordinates are available
                    NotificationCenter.default.post(name: .coordinatesLoaded, object: nil)
                    
                    completion(true)
                }
                
            } catch {
                print("DEBUG - COORDINATES: Failed to parse network data: \(error)")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    private static func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "events", withExtension: "json") else {
            print("DEBUG - COORDINATES: Could not find events.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let coordinateMap = try parseEventsData(data)
            
            cachedEventsData = coordinateMap
            lastLoadTime = Date()
            
            print("DEBUG - COORDINATES: Loaded \(coordinateMap.count) venue coordinates from bundled events.json")
            
            // Post notification that coordinates are available
            NotificationCenter.default.post(name: .coordinatesLoaded, object: nil)
            
        } catch {
            print("DEBUG - COORDINATES: Failed to load bundled events.json: \(error)")
        }
    }
    
    private static func parseEventsData(_ data: Data) throws -> [String: CLLocationCoordinate2D] {
        let eventsData = try JSONDecoder().decode(EventsData.self, from: data)
        var coordinateMap: [String: CLLocationCoordinate2D] = [:]
        
        for feature in eventsData.events.features {
            let coordinates = feature.geometry.coordinates
            guard coordinates.count >= 2 else { continue }
            
            let longitude = coordinates[0]
            let latitude = coordinates[1]
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Store with multiple possible name formats
            let longName = feature.properties.EventLongName
            let shortName = feature.properties.EventShortName
            
            coordinateMap[longName] = coordinate
            
            // Also store variations without "parkrun" suffix for better matching
            if longName.hasSuffix(" parkrun") {
                let nameWithoutSuffix = String(longName.dropLast(8))
                coordinateMap[nameWithoutSuffix] = coordinate
            }
            
            // Store short name version
            coordinateMap[shortName + " parkrun"] = coordinate
            coordinateMap[shortName] = coordinate
        }
        
        return coordinateMap
    }
    
    // MARK: - Fallback coordinates for critical venues
    private static func fallbackCoordinate(for venueName: String) -> CLLocationCoordinate2D? {
        let fallbackCoordinates: [String: CLLocationCoordinate2D] = [
            // Critical venues that should always work
            "Whiteley parkrun": CLLocationCoordinate2D(latitude: 50.8591, longitude: -1.2956),
            "Southampton parkrun": CLLocationCoordinate2D(latitude: 50.9097, longitude: -1.4044),
            "Bushy parkrun": CLLocationCoordinate2D(latitude: 51.4108, longitude: -0.3340),
            "Richmond parkrun": CLLocationCoordinate2D(latitude: 51.4613, longitude: -0.2909),
            
            // Inactive venues - store with multiple name variants
            "Crissy Field parkrun": CLLocationCoordinate2D(latitude: 37.8055, longitude: -122.4662),
            "Crissy Field": CLLocationCoordinate2D(latitude: 37.8055, longitude: -122.4662),
        ]
        
        return fallbackCoordinates[venueName]
    }
    
    // MARK: - Geocoding for inactive venues
    private static func geocodeVenue(_ venueName: String) {
        let geocoder = CLGeocoder()
        
        // Create search query - try various formats with better geographic specificity
        let baseSearchQueries = [
            venueName.replacingOccurrences(of: " parkrun", with: ""), // Without "parkrun"
            venueName.replacingOccurrences(of: " parkrun", with: " park"), // Replace with "park"
            venueName, // Original name
        ]
        
        // Add geographic specificity for known venues
        var searchQueries = baseSearchQueries
        if venueName.lowercased().contains("crissy") {
            searchQueries = [
                "Crissy Field San Francisco California",
                "Crissy Field San Francisco",
                "Crissy Field Golden Gate",
            ] + baseSearchQueries
        }
        
        func tryNextQuery(_ queries: [String]) {
            guard !queries.isEmpty else {
                print("DEBUG - COORDINATES: Geocoding failed for '\(venueName)' - no more queries to try")
                return
            }
            
            let query = queries.first!
            let remainingQueries = Array(queries.dropFirst())
            
            print("DEBUG - COORDINATES: Attempting to geocode '\(query)'")
            
            geocoder.geocodeAddressString(query) { placemarks, error in
                if let error = error {
                    print("DEBUG - COORDINATES: Geocoding error for '\(query)': \(error)")
                    tryNextQuery(remainingQueries)
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    print("DEBUG - COORDINATES: No location found for '\(query)'")
                    tryNextQuery(remainingQueries)
                    return
                }
                
                let coordinate = location.coordinate
                
                DispatchQueue.main.async {
                    geocodedCoordinates[venueName] = coordinate
                    print("DEBUG - COORDINATES: Geocoded '\(venueName)' to \(coordinate.latitude), \(coordinate.longitude)")
                    
                    // Post notification to refresh UI
                    NotificationCenter.default.post(name: .coordinatesLoaded, object: nil)
                }
            }
        }
        
        tryNextQuery(searchQueries)
    }
    
    // MARK: - Helper functions
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var dist = Array(0...b.count)
        
        for i in 1...a.count {
            var newDist = [i]
            
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    newDist.append(dist[j-1])
                } else {
                    newDist.append(1 + min(dist[j], dist[j-1], newDist[j-1]))
                }
            }
            
            dist = newDist
        }
        
        return dist[b.count]
    }
    
    // MARK: - Map region calculation
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
    
    // MARK: - Cache management
    static func clearCache() {
        cachedEventsData = nil
        geocodedCoordinates.removeAll()
        lastLoadTime = nil
        isLoading = false
        print("DEBUG - COORDINATES: Cache cleared")
    }
    
    static func preloadData() {
        loadEventsDataIfNeeded()
    }
}