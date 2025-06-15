# Test Setup Instructions

## Issue: Test Host Configuration

The unit tests cannot currently run via command line due to a missing test scheme configuration. The test target needs to be properly configured in Xcode.

## Solution: Create Test Scheme in Xcode

### Manual Setup Required:

1. **Open Xcode Project**
   ```bash
   open "../PR Bar Code.xcodeproj"
   ```

2. **Create Test Scheme**
   - Go to `Product` → `Scheme` → `Manage Schemes...`
   - Click the `+` button to add new scheme
   - Choose `5K QR CodeTests` as the target
   - Name it `5K QR CodeTests`
   - Ensure it's set to "Shared" so it's committed to git

3. **Configure Test Host**
   - Select the test scheme and click `Edit`
   - Go to the `Test` action
   - Ensure `5K QR CodeTests` target is listed
   - Verify the test host points to the main app

4. **Alternative: Run Tests in Xcode**
   - Open the project in Xcode
   - Select any test file
   - Press `Cmd+U` to run all tests
   - Or click the diamond icon next to individual tests

## Current Test Status

✅ **Test Files Created**: All 5 test files compile successfully  
✅ **Test Coverage**: 80+ test scenarios across core functionality  
✅ **Framework**: Uses modern Swift Testing framework  
❌ **Command Line**: Requires Xcode scheme configuration  

## Workaround: Manual Testing

Until the scheme is configured, tests can be run manually in Xcode:

1. Open `PR Bar Code.xcodeproj`
2. Navigate to test files in Project Navigator
3. Click the diamond icon next to test functions
4. Or press `Cmd+U` to run all tests

## Expected Test Results

When properly configured, all tests should pass:

- **ParkrunInfoTests**: Model validation and display name logic
- **CountryTests**: Enum values and website URL validation  
- **NotificationManagerTests**: Notification scheduling components
- **HTMLParsingTests**: Regex patterns and data extraction
- **QRCodeGenerationTests**: Core Image filter functionality

## Post-Setup Verification

Once the scheme is created, verify with:

```bash
xcodebuild test -project "../PR Bar Code.xcodeproj" -scheme "5K QR CodeTests" -destination "platform=iOS Simulator,name=iPhone 16,OS=latest"
```

This should run all tests and show successful results.