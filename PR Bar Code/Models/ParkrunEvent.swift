import SwiftData

@Model
class ParkrunEvent {
    var id: Int
    var name: String
    var location: String
    var latitude: Double
    var longitude: Double
    var countryCode: Int
    
    init(id: Int, name: String, location: String, latitude: Double, longitude: Double, countryCode: Int) {
        self.id = id
        self.name = name
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.countryCode = countryCode
    }
}