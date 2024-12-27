//
//  PR_Bar_CodeApp.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 14/12/2024.
//

import SwiftUI
import SwiftData

@main
struct PR_Bar_CodeApp: App {
    var body: some Scene {
        WindowGroup {
            QRCodeBarcodeView()
        }
        .modelContainer(for: ParkrunInfo.self) // Attach SwiftData Model Container
    }
}
