# AgentVault

> **Your AI accounts, always in sync**

AgentVault is a production-ready Flutter application for tracking free trial accounts across AI agent IDEs and tools. Never miss a reset deadline again.

## Features

- 🔐 **Secure Credential Storage** — Passwords encrypted with platform keychain/keystore via flutter_secure_storage
- 📊 **Smart Dashboard** — IDE cards sorted by urgency (needs reset → resetting soon → available)
- ⏰ **Push Notifications** — Configurable alerts before account resets (15min to 1 day advance)
- 🔄 **Auto-Sync** — AI IDE list fetched from configurable JSON URL, with offline fallback to bundled assets
- 🛡️ **Biometric Lock** — Face ID / fingerprint app protection via local_auth
- 🌐 **20+ Pre-loaded AI Tools** — Cursor, Windsurf, Bolt.new, Claude.ai, ChatGPT, and more
- 📱 **Responsive** — Adaptive grid layout for mobile (2-col), tablet (3-col), and desktop (4-col)
- 🌙 **Dark Mode** — Full light/dark theme (deep navy + electric blue palette)
- 🔃 **Auto-Updates** — Checks GitHub releases, one-tap APK install on Android
- 📴 **Offline First** — All data accessible without internet (Hive local database)

## Screenshots

_Add screenshots after first build_

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.3.0 (stable channel)
- Android SDK (API 21+) for Android builds
- Xcode 15+ for iOS builds

### Setup

```bash
git clone https://github.com/mr-wolf-gb/AI-Agent-Reset-Tracker.git
cd AI-Agent-Reset-Tracker
flutter pub get
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## CI/CD — Automated Releases

Push to `main` with a version bump in `pubspec.yaml` to trigger an automated release:

1. Update `version` in `pubspec.yaml`: `version: 1.0.1+2`
2. `git commit -am "chore: bump to 1.0.1" && git push origin main`
3. GitHub Actions automatically:
   - Runs `flutter analyze` and `flutter test`
   - Builds Android APK + AAB
   - Builds iOS IPA (no code signing)
   - Creates a GitHub Release with all artifacts attached

## AI Tools JSON Format

The app fetches its AI tools list from a configurable URL (default: this repo's `assets/data/ai_ides.json`).

```json
[
  {
    "id": "unique-slug",
    "name": "Tool Name",
    "website": "https://tool.com",
    "icon_url": "https://tool.com/favicon.ico",
    "type": "web-app",
    "description": "Brief description"
  }
]
```

**Supported types**: `desktop-ide`, `web-app`, `web-ide`, `plugin`, `cli`, `api`

When an IDE is removed from the master list, existing accounts display as "Unknown AI IDE" rather than being deleted.

## Architecture

```
lib/
├── core/
│   ├── constants/    # AppConstants, AppColors
│   ├── theme/        # Light + dark ThemeData
│   └── utils/        # DateFormatter, Validators
├── models/           # AiIde, Account, AppSettings, UpdateInfo (+ Hive TypeAdapters)
├── services/         # DatabaseService, SecureStorageService, NotificationService,
│                     # UpdateService, AiIdeSyncService, BiometricService
├── providers/        # Riverpod StateNotifierProviders
├── router/           # GoRouter with auth guard
├── screens/
│   ├── splash/       # Permissions + init + navigation
│   ├── auth/         # Biometric lock screen
│   ├── dashboard/    # IDE summary grid
│   ├── accounts/     # Account list + add/edit form
│   ├── ai_ides/      # IDE catalog + custom IDE creation
│   └── settings/     # Biometric, notifications, updates, sync
└── widgets/          # AppLogo, StatusBadge, IdeIcon, EmptyState, UpdateDialog, MainShell
```

**State**: Riverpod 2.x (StateNotifier pattern)  
**Database**: Hive 2.x (offline-first, manual TypeAdapters)  
**Security**: flutter_secure_storage (AES-256 via EncryptedSharedPreferences / iOS Keychain)  
**Navigation**: GoRouter 14.x with redirect guards  

## Database Schema

See [docs/SCHEMA.md](docs/SCHEMA.md) for full schema documentation.

## License

MIT
