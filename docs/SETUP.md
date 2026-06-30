# Development Setup

## Prerequisites

- Flutter SDK ≥ 3.3.0 (stable channel)
- Dart SDK ≥ 3.3.0
- **Android**: Android SDK, Java 17, ANDROID_HOME set
- **iOS**: macOS, Xcode 15+, CocoaPods

## Quick Start

```bash
git clone https://github.com/mr-wolf-gb/AI-Agent-Reset-Tracker.git
cd AI-Agent-Reset-Tracker
flutter pub get
flutter run
```

## Android-Specific Setup

### Exact Alarm Permission (Android 12+)
The app uses exact alarms for precise notification scheduling. On Android 12+:
1. Go to **Settings → Apps → Special app access → Alarms & reminders**
2. Enable for AgentVault

### APK Installation (Auto-Update Feature)
For the one-tap update feature to work:
1. Go to **Settings → Apps → Special app access → Install unknown apps**
2. Enable for AgentVault

## iOS-Specific Setup

```bash
cd ios && pod install --repo-update
```

Face ID / Touch ID works automatically on supported devices. The `NSFaceIDUsageDescription` key is already set in `Info.plist`.

## Running Tests

```bash
# Analyze (no fatal warnings)
flutter analyze --no-fatal-infos

# Unit/widget tests
flutter test
```

## Releasing a New Version

1. Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2   # format: semver+buildNumber
   ```
2. Commit and push to `main`:
   ```bash
   git commit -am "chore: bump version to 1.0.1"
   git push origin main
   ```
3. The `.github/workflows/release.yml` workflow:
   - Detects the version change
   - Checks if tag `v1.0.1` already exists (skips if so)
   - Runs `flutter analyze` + `flutter test`
   - Builds Android APK + AAB
   - Builds iOS IPA (no code signing)
   - Creates GitHub Release `v1.0.1` with all artifacts

## Customizing the AI Tools List

The master list of AI tools lives at `assets/data/ai_ides.json` (bundled) and is also hosted at:
```
https://raw.githubusercontent.com/mr-wolf-gb/AI-Agent-Reset-Tracker/main/assets/data/ai_ides.json
```

To add a new AI tool to the master list, include its reset configuration:
1. Add an entry to `assets/data/ai_ides.json`:
   ```json
   {
     "id": "new-tool",
     "name": "New Tool",
     "website": "...",
     "reset_period_hours": 24,
     "reset_presets": [3, 24]
   }
   ```
2. Commit and push — users' apps will sync on next launch

Custom IDEs added by users are never overwritten by sync (they have `isCustom: true`).

## Changing the GitHub Repo for Updates

Edit `lib/core/constants/app_constants.dart`:
```dart
static const String githubOwner = 'your-username';
static const String githubRepo = 'your-repo-name';
```

## Environment Variables

No environment variables required. All configuration lives in `AppConstants`.

## Architecture Decision Records

### Why Hive over SQLite?
Hive is simpler, faster for key-value object storage, and doesn't require a native dependency. For this app's data model (flat collections of AiIde and Account objects), Hive is sufficient and dramatically reduces boilerplate.

### Why manual TypeAdapters over code generation?
Manual Hive TypeAdapters avoid the `build_runner` dependency and associated complexity. The adapter code is straightforward and doesn't require regeneration on model changes — just increment field indices.

### Why Riverpod over Provider/Bloc?
Riverpod offers type-safe, testable state management without InheritedWidget scoping issues. The StateNotifier pattern gives clear separation between state and logic without the verbosity of Bloc.

### Why GoRouter?
GoRouter provides URL-based navigation with redirect guards, making the biometric lock screen trivially implementable as a router-level redirect.
