# PR Bar Code

A Swift/SwiftUI iOS and watchOS app for managing parkrun barcodes and tracking your parkrun journey.

## Features

### 📱 iOS App
- **Digital Barcode Storage**: Store and display your parkrun barcode digitally
- **Journey Tracking**: Comprehensive visualizations of your parkrun history
- **Family & Friends**: Manage multiple runner profiles and track their progress
- **Settings**: Customize app behavior and preferences

### ⌚ watchOS App
- **Quick Barcode Access**: Display your parkrun barcode directly from your wrist
- **Offline Support**: Works without iPhone connectivity
- **Optimized Interface**: Clean, minimal design perfect for race day

## Architecture

### Navigation Structure
- **Me Tab**: Your profile and main barcode display
- **Family Tab**: Manage multiple runner profiles
- **Journey Tab**: Detailed parkrun statistics and visualizations
- **Settings Tab**: App configuration and preferences

### Technical Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Data persistence and management
- **Universal App**: Single codebase for iOS and watchOS
- **Xcode 15+**: Built with latest development tools

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 18.1+ / watchOS 10.6+ deployment targets
- macOS 15.1+ for development

### Installation
1. Clone the repository
2. Open `PR Bar Code.xcodeproj` in Xcode
3. Build and run on your preferred target

### Development Setup
```bash
# Install fastlane for automation
gem install bundler
bundle install

# Run development build check
fastlane dev_check

# Run comprehensive tests
fastlane test_and_build
```

## Development Workflow

### Fastlane Automation
This project uses fastlane for automated testing, building, and versioning:

- **`fastlane dev_check`**: Quick build verification
- **`fastlane test`**: Run full test suite with coverage
- **`fastlane local_version_bump`**: Bump version numbers
- **`fastlane prepare_release`**: Complete release preparation

See [Fastlane Guide](docs/FASTLANE_GUIDE.md) for detailed documentation.

### Version Management
- **Semantic Versioning**: `MAJOR.MINOR.PATCH` format
- **Automated Builds**: Timestamp-based build numbers
- **Multi-Target**: Synchronized versioning for iOS and watchOS

## Project Structure

```
PR Bar Code/
├── PR Bar Code/               # iOS app source
├── PR Bar Code Watch App/     # watchOS app source
├── PR Bar CodeTests/          # iOS unit tests
├── PR Bar CodeUITests/        # iOS UI tests
├── fastlane/                  # Build automation
├── docs/                      # Documentation
└── README.md                  # This file
```

## Testing

### Unit Tests
```bash
# Run all tests
fastlane test

# Run specific test target
xcodebuild test -scheme "PR Bar Code" -destination "platform=iOS Simulator,name=iPhone 16"
```

### UI Tests
Comprehensive UI testing coverage for both iOS and watchOS targets.

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Run tests: `fastlane test_and_build`
4. Version bump: `fastlane prepare_release`
5. Create a Pull Request

## Versioning

This project follows semantic versioning and uses fastlane for automated version management:

- **Before PR**: Run `fastlane prepare_release` to bump version
- **Build Numbers**: Automatically generated timestamps
- **Git Tags**: Created automatically with version bumps

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions:
- Check existing [GitHub Issues](https://github.com/mattyg1/ParkrunBarcode/issues)
- Review the [Fastlane Guide](docs/FASTLANE_GUIDE.md)
- Open a new issue if needed

## Acknowledgments

- Built for the parkrun community
- Uses SwiftUI for modern iOS/watchOS development
- Automated with fastlane for reliable builds and deployments