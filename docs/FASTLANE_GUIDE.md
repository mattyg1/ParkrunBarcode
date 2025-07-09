# Fastlane Guide for PR Bar Code

## Overview
This guide covers the fastlane automation setup for PR Bar Code, including build verification, testing, and versioning workflows.

## Setup

### Prerequisites
1. Install Xcode command line tools:
   ```bash
   xcode-select --install
   ```

2. Install bundler and dependencies:
   ```bash
   gem install bundler
   bundle install
   ```

## Available Lanes

### 🧪 Testing & Build Verification

#### `fastlane test`
Runs the full test suite with code coverage.

```bash
bundle exec fastlane test
```

**What it does:**
- Runs tests on iPhone 16 simulator
- Generates code coverage reports
- Creates result bundle for detailed analysis
- Outputs results to `./test_output/`

#### `fastlane dev_check`
Quick build verification without archiving (fastest option).

```bash
bundle exec fastlane dev_check
```

**What it does:**
- Builds iOS app for simulator (no code signing)
- Builds watchOS app for simulator
- Verifies both targets compile successfully
- Skips archiving for speed

#### `fastlane test_and_build`
Comprehensive testing and build verification.

```bash
bundle exec fastlane test_and_build
```

**What it does:**
- Cleans previous build artifacts
- Runs full test suite
- Verifies both iOS and watchOS builds
- Most thorough validation

#### `fastlane pre_commit`
Pre-commit validation (ideal for git hooks).

```bash
bundle exec fastlane pre_commit
```

**What it does:**
- Ensures working directory is clean
- Runs development build check
- Fast validation for commit readiness

### 📦 Versioning & Release

#### `fastlane local_version_bump`
Bumps version and build numbers.

```bash
# Patch version (1.0.0 → 1.0.1)
bundle exec fastlane local_version_bump

# Minor version (1.0.0 → 1.1.0)
bundle exec fastlane local_version_bump bump:minor

# Major version (1.0.0 → 2.0.0)
bundle exec fastlane local_version_bump bump:major
```

**What it does:**
- Increments version number (patch/minor/major)
- Sets build number to timestamp (YYYYMMDDHHMM)
- Commits version changes
- Creates git tag
- Pushes to remote repository

#### `fastlane prepare_release`
Complete release preparation workflow.

```bash
# Prepare patch release
bundle exec fastlane prepare_release

# Prepare minor release
bundle exec fastlane prepare_release bump:minor

# Prepare major release
bundle exec fastlane prepare_release bump:major
```

**What it does:**
- Ensures you're on a feature branch (not main)
- Runs full test and build verification
- Bumps version and build numbers
- Commits and tags changes
- Pushes to remote

## 🔄 Recommended Workflow

### When to Run Fastlane for Versioning

**Answer: Run versioning BEFORE creating your PR, not after.**

Here's the recommended workflow:

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/my-new-feature

# Develop your feature...
# Make commits...

# Quick validation during development
bundle exec fastlane dev_check
```

### 2. Pre-PR Preparation
```bash
# Comprehensive testing and versioning
bundle exec fastlane prepare_release

# This will:
# - Run full tests
# - Verify builds
# - Bump version
# - Create git tag
# - Push to remote
```

### 3. Create PR
```bash
# Create PR with version already bumped
gh pr create --title "feat: my new feature" --body "Description..."
```

### 4. After PR Merge
```bash
# Switch back to main and pull latest
git checkout main
git pull origin main

# Your version bump is already included in main
```

## 🔧 Git Hook Integration

### Pre-commit Hook (Optional)
Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
echo "Running pre-commit checks..."
bundle exec fastlane pre_commit
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## 📊 Output Directories

- `./test_output/` - Test results and coverage reports
- `./build/` - Build artifacts (created by Xcode)

## 🚨 Troubleshooting

### Common Issues

#### 1. Bundle Exec Error
```bash
# If you get "Could not locate Gemfile"
bundle install
```

#### 2. Simulator Not Found
```bash
# List available simulators
xcrun simctl list devices
```

#### 3. Git Status Not Clean
```bash
# Check what files are modified
git status

# Commit or stash changes
git stash
```

#### 4. Build Failures
```bash
# Clean build folder
rm -rf build/
bundle exec fastlane clean_build_artifacts
```

## 🎯 Best Practices

1. **Always run tests before pushing:**
   ```bash
   bundle exec fastlane test_and_build
   ```

2. **Use prepare_release for version bumps:**
   ```bash
   bundle exec fastlane prepare_release
   ```

3. **Quick validation during development:**
   ```bash
   bundle exec fastlane dev_check
   ```

4. **Version bump BEFORE PR creation, not after**

5. **Use semantic versioning:**
   - `patch` - Bug fixes (1.0.0 → 1.0.1)
   - `minor` - New features (1.0.0 → 1.1.0)
   - `major` - Breaking changes (1.0.0 → 2.0.0)

## 🔮 Future Enhancements

- [ ] TestFlight deployment
- [ ] App Store submission
- [ ] Slack notifications
- [ ] Crash reporting integration
- [ ] Performance testing
- [ ] Screenshot generation

## 📞 Support

For issues or questions about this fastlane setup, check:
- [Fastlane Documentation](https://docs.fastlane.tools/)
- Project README.md
- GitHub Issues