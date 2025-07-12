# Local CI/CD Pipeline - 5K QR Code

## Overview
Comprehensive local development automation pipeline to ensure quality and streamline feature development. This document outlines automated workflows that kick off quality checks, testing, and validation without manual intervention.

---

## 🎯 Pipeline Philosophy

### Goals
- **Automate Quality**: No manual "remember to run tests" 
- **Fast Feedback**: Catch issues before they become problems
- **Consistent Process**: Same quality checks every time
- **Developer Productivity**: Focus on features, not process

### Trigger Points
1. **On Commit**: Basic quality gates (30 seconds)
2. **On Push**: Comprehensive validation (5 minutes)
3. **Feature Complete**: Full quality assessment (15 minutes)
4. **Release Ready**: App Store preparation (30+ minutes)

---

## 🏗 Multi-Layer Architecture

### Layer 1: Git Hooks (Automatic)
**Triggers**: Automatic on git operations
**Purpose**: Prevent bad code from entering repository
**Speed**: Fast (30 seconds max)

### Layer 2: Fastlane (Command-driven)
**Triggers**: Manual execution (`fastlane [lane]`)
**Purpose**: Comprehensive quality and build automation
**Speed**: Medium to Slow (5-30 minutes)

### Layer 3: Make/Scripts (Utility)
**Triggers**: Manual execution (`make [target]`)
**Purpose**: Simple, common development tasks
**Speed**: Fast (1-5 minutes)

### Layer 4: GitHub Actions (Optional)
**Triggers**: PR creation, branch push
**Purpose**: Remote validation and team collaboration
**Speed**: Medium (10-20 minutes)

---

## 🚦 Stage Definitions

### Stage 1: Quick Check (Pre-commit)
**Duration**: ≤30 seconds
**Purpose**: Block obviously bad commits
**Triggers**: `git commit`

```bash
Quick Check Pipeline:
1. SwiftLint validation (5s)
2. Debug logging check (2s) 
3. Basic compilation (15s)
4. Critical unit tests (8s)
```

**Success**: Commit proceeds
**Failure**: Commit blocked with clear error message

### Stage 2: Validation Check (Pre-push)
**Duration**: ≤5 minutes  
**Purpose**: Ensure branch quality before sharing
**Triggers**: `git push`

```bash
Validation Pipeline:
1. Full test suite (3m)
2. Code coverage check (30s)
3. Static analysis (1m)
4. Build verification (30s)
```

**Success**: Push proceeds
**Failure**: Push blocked, detailed report generated

### Stage 3: Feature Complete
**Duration**: 5-15 minutes
**Purpose**: Comprehensive feature validation
**Triggers**: `fastlane feature_complete`

```bash
Feature Complete Pipeline:
1. All tests + coverage analysis (5m)
2. Performance benchmarks (3m)
3. Memory leak detection (2m)
4. Multi-device build test (3m)
5. Quality report generation (2m)
```

**Output**: Detailed quality report with coverage, performance metrics

### Stage 4: Release Ready
**Duration**: 15-30 minutes
**Purpose**: App Store submission preparation
**Triggers**: `fastlane release_ready`

```bash
Release Ready Pipeline:
1. Everything from Feature Complete (15m)
2. App Store compliance check (5m)
3. Privacy policy validation (2m)
4. Archive build creation (5m)
5. TestFlight upload (3m)
6. Version bump and tagging (1m)
```

**Output**: Ready-to-submit app with all compliance checks passed

---

## 🔧 Implementation Details

### Git Hooks Configuration

#### Pre-commit Hook
```bash
#!/bin/bash
# File: .git/hooks/pre-commit

echo "🚦 Running pre-commit quality checks..."

# 1. SwiftLint validation
if which swiftlint >/dev/null; then
  echo "   → Running SwiftLint..."
  swiftlint --strict --quiet
  if [ $? -ne 0 ]; then
    echo "❌ SwiftLint failed. Fix issues before committing."
    exit 1
  fi
else
  echo "⚠️  SwiftLint not installed"
fi

# 2. Debug logging check  
echo "   → Checking for debug statements..."
if grep -r "print(\"DEBUG" "PR Bar Code/" --include="*.swift"; then
  echo "❌ Debug print statements found. Use AppLogger instead."
  exit 1
fi

# 3. Basic compilation check
echo "   → Verifying compilation..."
xcodebuild build -project "PR Bar Code.xcodeproj" -scheme "PR Bar Code" -quiet >/dev/null
if [ $? -ne 0 ]; then
  echo "❌ Build failed. Fix compilation errors."
  exit 1
fi

# 4. Critical tests
echo "   → Running critical tests..."
xcodebuild test -project "PR Bar Code.xcodeproj" -scheme "PR Bar Code" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" \
  -only-testing:"PR Bar CodeTests/QRCodeGenerationTests" \
  -quiet >/dev/null
if [ $? -ne 0 ]; then
  echo "❌ Critical tests failed."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
```

#### Pre-push Hook
```bash
#!/bin/bash
# File: .git/hooks/pre-push

echo "🧪 Running pre-push validation..."

# Run full test suite with coverage
fastlane test_with_coverage

if [ $? -ne 0 ]; then
  echo "❌ Pre-push validation failed."
  exit 1
fi

echo "✅ Pre-push validation passed!"
```

### Fastlane Configuration

#### Enhanced Fastfile
```ruby
# File: fastlane/Fastfile

default_platform(:ios)

platform :ios do
  
  # Quick test lane for pre-push
  lane :test_with_coverage do
    run_tests(
      project: "PR Bar Code.xcodeproj",
      scheme: "PR Bar Code",
      devices: ["iPhone 16 Pro"],
      code_coverage: true,
      output_directory: "./test_output",
      skip_slack: true
    )
    
    # Check coverage threshold
    coverage_percentage = coverage_check
    if coverage_percentage < 75
      UI.user_error!("Code coverage #{coverage_percentage}% below 75% threshold")
    end
  end
  
  # Comprehensive feature validation
  lane :feature_complete do
    UI.header("🚀 Feature Complete Pipeline")
    
    # 1. Full test suite
    UI.message("Running full test suite...")
    test_with_coverage
    
    # 2. Performance benchmarks
    UI.message("Running performance tests...")
    run_tests(
      project: "PR Bar Code.xcodeproj", 
      scheme: "PR Bar Code",
      devices: ["iPhone 16 Pro"],
      only_testing: ["PerformanceTests"]
    )
    
    # 3. Static analysis
    UI.message("Running static analysis...")
    xcodebuild(
      project: "PR Bar Code.xcodeproj",
      scheme: "PR Bar Code",
      configuration: "Debug",
      analyze: true
    )
    
    # 4. Multi-device build test
    UI.message("Testing multi-device builds...")
    build_test_multiple_devices
    
    # 5. Generate reports
    UI.message("Generating quality reports...")
    generate_quality_report
    
    UI.success("✅ Feature complete validation passed!")
    UI.message("📊 Check ./reports/ for detailed analysis")
  end
  
  # Release preparation
  lane :release_ready do
    UI.header("🏪 Release Ready Pipeline")
    
    # 1. Feature complete validation
    feature_complete
    
    # 2. App Store compliance
    UI.message("Checking App Store compliance...")
    app_store_compliance_check
    
    # 3. Privacy validation
    UI.message("Validating privacy compliance...")
    privacy_check
    
    # 4. Archive build
    UI.message("Creating archive build...")
    build_app(
      project: "PR Bar Code.xcodeproj",
      scheme: "PR Bar Code",
      configuration: "Release",
      output_directory: "./builds"
    )
    
    # 5. Version management
    UI.message("Managing version...")
    current_version = get_version_number
    next_version = increment_version_number
    
    # 6. TestFlight upload (optional)
    if UI.confirm("Upload to TestFlight?")
      upload_to_testflight(
        skip_waiting_for_build_processing: true
      )
    end
    
    # 7. Git tagging
    add_git_tag(tag: "v#{next_version}")
    push_git_tags
    
    UI.success("🎉 Release ready! Version #{next_version}")
  end
  
  # Utility lanes
  lane :quick_quality do
    swiftlint(strict: true)
    run_tests(
      project: "PR Bar Code.xcodeproj",
      scheme: "PR Bar Code", 
      devices: ["iPhone 16 Pro"],
      skip_build: true
    )
  end
  
  # Helper methods
  private_lane :build_test_multiple_devices do
    devices = [
      "iPhone 16 Pro",
      "iPhone 14", 
      "iPad Air (5th generation)"
    ]
    
    devices.each do |device|
      xcodebuild(
        project: "PR Bar Code.xcodeproj",
        scheme: "PR Bar Code",
        destination: "platform=iOS Simulator,name=#{device}",
        build: true
      )
    end
  end
  
  private_lane :coverage_check do
    # Parse coverage from xcresult bundle
    # Return coverage percentage
    75 # Placeholder
  end
  
  private_lane :generate_quality_report do
    # Generate HTML report with:
    # - Test results
    # - Coverage metrics  
    # - Performance benchmarks
    # - Static analysis results
  end
  
  private_lane :app_store_compliance_check do
    # Check for:
    # - Privacy policy links
    # - Required app metadata
    # - Entitlements validation
    # - Bundle ID verification
  end
  
  private_lane :privacy_check do
    # Validate:
    # - No hardcoded personal data
    # - Proper data collection disclosure
    # - Network usage compliance
  end
end
```

### Make Configuration

#### Makefile for Common Tasks
```make
# File: Makefile

.PHONY: help quality test build clean install setup

# Default target
help:
	@echo "Available targets:"
	@echo "  setup     - Install dependencies and configure environment"
	@echo "  quality   - Run quick quality checks"
	@echo "  test      - Run full test suite"
	@echo "  build     - Build for all targets"
	@echo "  clean     - Clean build artifacts"
	@echo "  feature   - Run feature complete pipeline"
	@echo "  release   - Run release ready pipeline"

# Environment setup
setup:
	@echo "🛠  Setting up development environment..."
	brew install swiftlint
	gem install bundler
	bundle install
	chmod +x .git/hooks/pre-commit
	chmod +x .git/hooks/pre-push
	@echo "✅ Setup complete!"

# Quick quality check
quality:
	@echo "🚦 Running quality checks..."
	swiftlint --strict
	xcodebuild build -project "PR Bar Code.xcodeproj" -scheme "PR Bar Code" -quiet

# Full test suite
test:
	@echo "🧪 Running tests..."
	fastlane test_with_coverage

# Build verification
build:
	@echo "🏗  Building..."
	xcodebuild build -project "PR Bar Code.xcodeproj" -scheme "PR Bar Code"
	xcodebuild build -project "PR Bar Code.xcodeproj" -scheme "5K QR Code Watch App Watch App"

# Clean artifacts
clean:
	@echo "🧹 Cleaning..."
	xcodebuild clean -project "PR Bar Code.xcodeproj" -scheme "PR Bar Code"
	rm -rf test_output/
	rm -rf reports/
	rm -rf builds/

# Feature complete pipeline
feature:
	@echo "🚀 Running feature complete pipeline..."
	fastlane feature_complete

# Release ready pipeline  
release:
	@echo "🏪 Running release ready pipeline..."
	fastlane release_ready

# Install git hooks
install-hooks:
	@echo "🪝 Installing git hooks..."
	cp scripts/pre-commit .git/hooks/pre-commit
	cp scripts/pre-push .git/hooks/pre-push
	chmod +x .git/hooks/pre-commit
	chmod +x .git/hooks/pre-push
```

### GitHub Actions (Optional)

#### PR Validation Workflow
```yaml
# File: .github/workflows/pr-validation.yml
name: PR Validation

on:
  pull_request:
    branches: [develop, main]

jobs:
  quality:
    runs-on: macos-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.2'
        
    - name: Install dependencies
      run: |
        brew install swiftlint
        gem install bundler
        bundle install
        
    - name: SwiftLint
      run: swiftlint --strict
      
    - name: Run tests
      run: fastlane test_with_coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        
    - name: Comment PR
      uses: actions/github-script@v6
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: '✅ Quality checks passed!'
          })
```

---

## 📱 VS Code Integration

### Tasks Configuration
```json
// File: .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Quality Check",
            "type": "shell",
            "command": "make quality",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "Feature Complete",
            "type": "shell", 
            "command": "fastlane feature_complete",
            "group": "build"
        },
        {
            "label": "Release Ready",
            "type": "shell",
            "command": "fastlane release_ready", 
            "group": "build"
        }
    ]
}
```

### Keyboard Shortcuts
```json
// File: .vscode/keybindings.json
[
    {
        "key": "cmd+shift+q",
        "command": "workbench.action.tasks.runTask",
        "args": "Quality Check"
    },
    {
        "key": "cmd+shift+f",
        "command": "workbench.action.tasks.runTask", 
        "args": "Feature Complete"
    }
]
```

---

## 🎯 Usage Patterns

### Daily Development Flow
```bash
# Start feature
git checkout -b feature/my-feature

# Make changes, automatic quality on commit
git add .
git commit -m "feat: add new feature"  # ← Triggers pre-commit hook

# Before pushing (or automatic on push)
git push origin feature/my-feature     # ← Triggers pre-push hook

# Feature complete validation
make feature                           # or fastlane feature_complete

# Ready for PR
# (GitHub Actions run automatically)
```

### Release Flow
```bash
# Prepare release
git checkout develop
git pull origin develop

# Full release validation
make release                           # or fastlane release_ready

# If all passes:
# - Archive created
# - TestFlight uploaded 
# - Version tagged
# - Ready for App Store
```

---

## 📊 Pipeline Metrics

### Performance Targets
- **Pre-commit**: <30 seconds (blocking)
- **Pre-push**: <5 minutes (blocking)
- **Feature Complete**: <15 minutes (reporting)
- **Release Ready**: <30 minutes (comprehensive)

### Quality Gates
- **SwiftLint**: 0 errors, <10 warnings
- **Test Coverage**: >75% overall
- **Test Success**: 100% passing
- **Build Success**: All platforms
- **Performance**: Within benchmarks

### Success Criteria
- **Developer Productivity**: Faster feature delivery
- **Bug Reduction**: Fewer production issues
- **Release Confidence**: Consistent quality
- **Team Alignment**: Standardized process

---

## 🛠 Setup Instructions

### Initial Setup
```bash
# 1. Install dependencies
make setup

# 2. Configure git hooks
make install-hooks

# 3. Verify setup
make quality

# 4. Test full pipeline
make feature
```

### Team Onboarding
```bash
# New team member setup
git clone <repository>
cd PR\ Bar\ Code
make setup
```

---

## 🔧 Customization Options

### Pipeline Variants

#### Light Pipeline (Faster)
- Skip performance tests
- Reduce device matrix
- Basic coverage only

#### Heavy Pipeline (Comprehensive)  
- Extended device testing
- Memory profiling
- Security scanning
- Documentation generation

#### CI/CD Integration
- Slack notifications
- Jira integration
- Deployment automation
- Artifact management

### Configuration Files
- `.swiftlint.yml` - Linting rules
- `fastlane/Fastfile` - Build automation
- `Makefile` - Simple commands
- `.github/workflows/` - CI/CD workflows

---

## 📈 Benefits

### For Developers
- **Faster Feedback**: Catch issues immediately
- **Consistent Quality**: Same standards every time
- **Less Manual Work**: Automation handles routine tasks
- **Confidence**: Know your code is ready

### For Project
- **Higher Quality**: Systematic quality assurance
- **Faster Releases**: Streamlined process
- **Fewer Bugs**: Comprehensive testing
- **Better Maintainability**: Consistent standards

### For App Store
- **Release Confidence**: All compliance checks automated
- **Professional Quality**: Industry-standard processes
- **Faster Approval**: Fewer rejection reasons
- **User Experience**: Better app quality

---

*Last Updated: July 12, 2025*
*Next Review: After pipeline implementation and testing*