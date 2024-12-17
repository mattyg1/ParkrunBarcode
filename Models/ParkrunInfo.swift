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