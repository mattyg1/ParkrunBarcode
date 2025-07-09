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

## Branching Strategy

### Main Branches
- **`main`** - Production-ready code (App Store releases)
- **`develop`** - Integration branch for features (TestFlight releases)

### Feature Branches
- **`feature/*`** - Individual features (merge to `develop`)
- **`hotfix/*`** - Critical fixes (merge to both `main` and `develop`)
- **`release/*`** - Release preparation (merge to `main` and `develop`)

## Workflow for Pull Requests

### Feature Development (Standard Workflow)

**ALWAYS follow this workflow when developing features:**

1. **Create feature branch from develop**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```

2. **Version bump** (patch by default):
   ```bash
   fastlane local_version_bump bump:patch
   ```

3. **Commit changes**:
   ```bash
   git add -A
   git commit -m "feat: your feature description"
   ```

4. **Create PR to develop**:
   ```bash
   gh pr create --base develop --title "feat: your feature" --body "your description"
   ```

### Release Workflow

**For releasing to TestFlight/App Store:**

1. **Create release branch from develop**:
   ```bash
   git checkout develop
   git checkout -b release/1.x.0
   ```

2. **Version bump for release**:
   ```bash
   fastlane local_version_bump bump:minor  # or major
   ```

3. **Test and finalize release**:
   ```bash
   git commit -m "chore: prepare release 1.x.0"
   ```

4. **Create PR to main**:
   ```bash
   gh pr create --base main --title "release: 1.x.0" --body "Release notes..."
   ```

5. **After merge, sync develop**:
   ```bash
   git checkout develop
   git merge main
   git push origin develop
   ```

### Hotfix Workflow

**For critical production fixes:**

1. **Create hotfix branch from main**:
   ```bash
   git checkout main
   git checkout -b hotfix/critical-fix
   ```

2. **Version bump** (patch):
   ```bash
   fastlane local_version_bump bump:patch
   ```

3. **Create PRs to both main and develop**:
   ```bash
   gh pr create --base main --title "hotfix: critical fix"
   gh pr create --base develop --title "hotfix: critical fix"
   ```

### Version Bump Types

- `bump:patch` - Bug fixes (1.1.0 → 1.1.1) - **default for features**
- `bump:minor` - New features (1.1.0 → 1.2.0) - **for releases**
- `bump:major` - Breaking changes (1.1.0 → 2.0.0) - **for major releases**

## Build Commands

This is a standard SwiftUI iOS project. **IMPORTANT: Always run these build commands before committing code to ensure compatibility:**

### Fastlane Commands (Recommended)
```bash
# Version bump and build verification
fastlane local_version_bump bump:patch

# Quick build verification
fastlane dev_check

# Run full test suite
fastlane test

# Comprehensive testing and build verification
fastlane test_and_build
```

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