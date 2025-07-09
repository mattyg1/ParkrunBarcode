# fastlane documentation

----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

Install dependencies:
```sh
bundle install
```

# Available Actions

## iOS

### ios test
```sh
[bundle exec] fastlane ios test
```
Runs the full test suite with code coverage on iPhone 16 simulator.

### ios dev_check
```sh
[bundle exec] fastlane ios dev_check
```
Quick build verification for both iOS and watchOS targets without archiving.

### ios pre_commit
```sh
[bundle exec] fastlane ios pre_commit
```
Pre-commit validation - ensures clean git status and successful build.

### ios test_and_build
```sh
[bundle exec] fastlane ios test_and_build
```
Comprehensive testing and build verification for both targets.

### ios local_version_bump
```sh
[bundle exec] fastlane ios local_version_bump
```
Bumps version (patch by default) and build number, commits and tags.

Options:
- `bump:patch` (default) - 1.0.0 → 1.0.1
- `bump:minor` - 1.0.0 → 1.1.0  
- `bump:major` - 1.0.0 → 2.0.0

### ios prepare_release
```sh
[bundle exec] fastlane ios prepare_release
```
Complete release preparation: tests, builds, version bump, and git operations.

----

## 📚 Detailed Documentation

For comprehensive usage instructions, workflow recommendations, and troubleshooting, see:

**[📖 Fastlane Guide](../docs/FASTLANE_GUIDE.md)**

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).