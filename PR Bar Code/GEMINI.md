# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS app called "PR Bar Code" that generates QR codes and barcodes for Parkrun participant IDs. The app stores user information locally using SwiftData and can communicate with Apple Watch via WatchConnectivity. Includes companion watchOS app for displaying QR codes on Apple Watch.

## Key Architecture

- **SwiftData Models**: Uses SwiftData for local persistence with two main models:
  - `ParkrunInfo`: Stores user's personal information (ID, name, home parkrun, country)
  - `ParkrunEvent`: Stores event data fetched from external API
- **Single View Architecture**: Main interface is `QRCodeBarcodeView` with tabbed sections for personal/location info
- **Core Image Integration**: Uses CIFilter for QR code and Code128 barcode generation
- **Watch Connectivity**: `WatchSessionManager` handles communication with paired Apple Watch
- **Country Enum**: Static list of supported Parkrun countries with integer codes

## Data Flow

1. User enters Parkrun ID (format: A followed by numbers, e.g., A12345)
2. Data is validated and saved to SwiftData
3. QR/barcode is generated using Core Image filters
4. Information is sent to Apple Watch if connected
5. External event data can be fetched from `https://images.parkrun.com/events.json`

## Build Commands

This is a standard SwiftUI iOS project. **IMPORTANT: Always run these build commands before committing code to ensure compatibility:**

### Required Pre-Commit Build Tests
```bash
# Build for iPhone 16 (primary target)
xcodebuild -project "../PR Bar Code.xcodeproj" -scheme "PR Bar Code" -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" build

# Build for Apple Watch Series 10 (watch target)
xcodebuild -project "../PR Bar Code.xcodeproj" -scheme "5K QR Code Watch App Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
```

### Development Build Commands
- Open the project in Xcode
- Build with Cmd+B
- Run with Cmd+R  
- Test with Cmd+U

### Build Verification
Both iOS and watchOS builds must succeed with "BUILD SUCCEEDED" before any code commits. This ensures compatibility across both platforms and prevents integration issues.

## watchOS Target Setup (Manual Steps Required)

The watchOS app files are created but require Xcode target configuration:

1. **Create watchOS Target in Xcode:**
   - File → New → Target → Watch App
   - Name: "PR Bar Code Watch App"
   - Bundle ID: com.matthewgardner.PR-Bar-Code.watchkitapp

2. **Add Files to watchOS Target:**
   - `PR Bar Code Watch App/PR_Bar_Code_Watch_AppApp.swift`
   - `PR Bar Code Watch App/Views/ContentView.swift`
   - `PR Bar Code Watch App/Managers/WatchConnectivityManager.swift`

3. **Add Frameworks to watchOS Target:**
   - WatchConnectivity.framework
   - CoreImage.framework

## Code Patterns

- All SwiftData models use `@Model` macro
- ParkrunInfo uses `@Attribute(.unique)` for parkrunID
- UI follows SwiftUI declarative patterns with `@State` for local state
- Uses `@Environment(\.modelContext)` for SwiftData operations
- Watch connectivity uses singleton pattern (`WatchSessionManager.shared`)
- watchOS app uses delegate pattern for Watch Connectivity communication