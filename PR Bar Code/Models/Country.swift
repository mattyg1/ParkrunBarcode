//
//  Country.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 17/12/2024.
//


enum Country: Int, CaseIterable {
    case australia = 3
    case austria = 4
    case canada = 14
    case denmark = 23
    case finland = 30
    case france = 31
    case germany = 32
    case ireland = 42
    case italy = 44
    case japan = 46
    case lithuania = 54
    case malaysia = 57
    case netherlands = 64
    case newZealand = 65
    case norway = 67
    case poland = 74
    case singapore = 82
    case southAfrica = 85
    case sweden = 88
    case unitedKingdom = 97
    case unitedStates = 98

    var name: String {
        switch self {
        case .australia:     return "Australia"
        case .austria:       return "Austria"
        case .canada:        return "Canada"
        case .denmark:       return "Denmark"
        case .finland:       return "Finland"
        case .france:        return "France"
        case .germany:       return "Germany"
        case .ireland:       return "Ireland"
        case .italy:         return "Italy"
        case .japan:         return "Japan"
        case .lithuania:     return "Lithuania"
        case .malaysia:      return "Malaysia"
        case .netherlands:   return "Netherlands"
        case .newZealand:    return "New Zealand"
        case .norway:        return "Norway"
        case .poland:        return "Poland"
        case .singapore:     return "Singapore"
        case .southAfrica:   return "South Africa"
        case .sweden:        return "Sweden"
        case .unitedKingdom: return "United Kingdom"
        case .unitedStates:  return "United States"
        }
    }
}