import SwiftUI
import SwiftData

struct Event: Codable {
    let id: Int
    let properties: EventProperties
    let geometry: EventGeometry
}

struct EventProperties: Codable {
    let eventname: String
    let EventLongName: String
    let EventLocation: String
    let countrycode: Int
}

struct EventGeometry: Codable {
    let coordinates: [Double]
}

class EventDownloader {
    static let shared = EventDownloader()

    func fetchAndSaveEvents(modelContext: ModelContext) async {
        guard let url = URL(string: "https://images.parkrun.com/events.json") else { return }
        
        do {
            // Fetch JSON
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decode JSON
            let decodedJSON = try JSONDecoder().decode([String: [Event]].self, from: data)
            let events = decodedJSON["features"] ?? []
            
            // Overwrite existing data
            try modelContext.delete(model: ParkrunEvent.self)
            
            // Save new events
            for event in events {
                let newEvent = ParkrunEvent(
                    id: event.id,
                    name: event.properties.EventLongName,
                    location: event.properties.EventLocation,
                    latitude: event.geometry.coordinates[1],
                    longitude: event.geometry.coordinates[0],
                    countryCode: event.properties.countrycode
                )
                modelContext.insert(newEvent)
            }
            
            try modelContext.save()
            print("Events saved successfully!")
        } catch {
            print("Failed to fetch or save events: \(error)")
        }
    }
}