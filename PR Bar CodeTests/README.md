# PR Bar Code Unit Tests

This directory contains comprehensive unit tests for the PR Bar Code iOS application using Swift Testing framework.

## Test Coverage

### 1. ParkrunInfoTests.swift
Tests for the `ParkrunInfo` model class:
- Initialization with required and optional fields
- Display name generation logic
- Update display name functionality
- Identifiable protocol conformance
- Default value validation

### 2. CountryTests.swift
Tests for the `Country` enum:
- Raw value validation for all countries
- Country name verification
- Website URL validation
- HTTPS and domain requirements
- Case iteration and uniqueness
- Raw value initialization

### 3. NotificationManagerTests.swift
Tests for the `NotificationManager` class:
- Singleton pattern verification
- Initial state validation
- Notification identifier consistency
- Date component configuration
- Notification content structure
- UserDefaults key validation

### 4. HTMLParsingTests.swift
Tests for HTML parsing functionality:
- Parkrun ID validation regex
- Name extraction from HTML
- Total parkruns extraction
- Date and time parsing
- Event name and URL extraction
- Complex HTML integration testing
- Edge case handling (empty/malformed HTML)
- Profile URL generation

### 5. QRCodeGenerationTests.swift
Tests for QR code and barcode generation:
- Core Image filter initialization
- Data input validation
- Image output generation
- Scaling transformations
- CIContext and CGImage conversion
- UIImage creation
- Different parkrun ID formats
- Special character and Unicode handling

## Running Tests

### Command Line
```bash
xcodebuild test -project "../PR Bar Code.xcodeproj" -scheme "PR Bar Code" -destination "platform=iOS Simulator,name=iPhone 16,OS=latest"
```

### Xcode
1. Open `PR Bar Code.xcodeproj`
2. Select the test scheme
3. Press `Cmd+U` to run all tests
4. Use Test Navigator (Cmd+6) to run specific test files

## Test Framework

These tests use Swift Testing framework (introduced in Xcode 16) which provides:
- Modern async/await support
- Better error reporting
- Improved test organization
- Enhanced assertions with `#expect()`

## Test Organization

Tests are organized by component with clear naming conventions:
- Each test method describes what it's testing
- Related tests are grouped in structs
- Test data follows realistic parkrun patterns
- Edge cases and error conditions are covered

## Coverage Areas

✅ **Model Layer**: ParkrunInfo, Country enums  
✅ **Business Logic**: Notification scheduling, HTML parsing  
✅ **Core Image**: QR/barcode generation  
✅ **Data Validation**: Input validation, regex patterns  
✅ **Error Handling**: Edge cases, malformed input  

## Future Test Additions

Potential areas for additional testing:
- UI component testing with SwiftUI
- WatchConnectivity integration tests
- SwiftData model persistence tests
- Network request mocking
- User interaction testing