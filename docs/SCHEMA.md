# Database Schema

AgentVault uses **Hive** for local offline-first storage. No SQLite, no raw queries — pure Dart object persistence.

## Hive Boxes

### `ai_ides` — `Box<AiIde>` (TypeAdapter typeId = 0)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique slug (e.g. `cursor`, `bolt-new`) |
| name | String | Display name (e.g. `Cursor`) |
| website | String | Official website URL |
| iconUrl | String | Favicon / icon URL for display |
| type | String | One of: `desktop-ide`, `web-app`, `web-ide`, `plugin`, `cli`, `api` |
| isCustom | bool | `true` if user-created, never overwritten by sync |
| isRemoved | bool | `true` if removed from master JSON list (accounts still shown) |
| updatedAt | DateTime | Last sync/update timestamp |
| description | String? | Optional short description |

**Sync behavior**: On sync, non-custom IDEs are updated from the master list. IDEs absent from master list are marked `isRemoved = true`. Accounts for removed IDEs display "Unknown AI IDE" but are never deleted.

---

### `accounts` — `Box<Account>` (TypeAdapter typeId = 1)

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID v4 |
| aiIdeId | String | Foreign key → AiIde.id |
| email | String | Account email address |
| resetTime | DateTime? | When trial/free tier resets |
| isActive | bool | Whether account is currently tracked |
| notificationEnabled | bool | Whether to schedule reset alert |
| notes | String | Optional user notes |
| createdAt | DateTime | Creation timestamp |
| updatedAt | DateTime | Last modified timestamp |

**Password storage**: Passwords are **not stored in Hive**. They are stored via `flutter_secure_storage` with key pattern `account_pw_{id}`:
- **Android**: EncryptedSharedPreferences (AES-256 backed by Android Keystore)
- **iOS**: Keychain with `first_unlock` accessibility

**Status computation** (derived, not stored):

| Condition | Status | Color |
|-----------|--------|-------|
| `isActive = false` | Inactive | Grey |
| `resetTime = null` | Available | Green |
| `resetTime` in the past | Needs Reset | Red |
| `resetTime` within 24h | Resetting Soon | Amber |
| `resetTime` > 24h away | Available | Green |

---

### `app_settings` — `Box<AppSettings>` (TypeAdapter typeId = 2)

Single object stored at key `settings`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| biometricEnabled | bool | false | Require biometric auth on app open |
| notificationsEnabled | bool | true | Global notification toggle |
| doNotDisturbEnabled | bool | false | Suppress notifications during DND hours |
| doNotDisturbStartHour | int | 22 | DND start hour (0–23) |
| doNotDisturbEndHour | int | 8 | DND end hour (0–23) |
| notificationSound | String | 'default' | Notification sound preference |
| notificationAdvanceMinutes | int | 60 | Minutes before reset time to notify |
| lastUpdateCheck | DateTime? | null | Last GitHub release check time |
| latestAvailableVersion | String? | null | Latest version tag from GitHub |
| updateDownloadUrl | String? | null | APK download URL from latest release |
| aiIdeListUrl | String | (GitHub raw) | URL to fetch AI IDE master list |
| lastAiIdeSync | DateTime? | null | Last successful sync timestamp |
| hasCompletedOnboarding | bool | false | First-launch flag |
| appLockEnabled | bool | false | Companion to biometricEnabled |

---

## Secure Storage Keys

| Key Pattern | Value |
|-------------|-------|
| `account_pw_{accountId}` | Encrypted account password |
| `app_pin` | Optional 4–6 digit PIN (future feature) |

---

## Notification Scheduling

Each account with `notificationEnabled = true` and a non-null `resetTime` gets a scheduled local notification:
- Fires at: `resetTime - notificationAdvanceMinutes`
- Notification ID: `accountId.hashCode.abs()` (stable, unique per account)
- Payload: `"accountId:ideId"` (for future deep link navigation)
- Rescheduled on: account save, settings change, app restart

---

## Default AI IDE List URL

```
https://raw.githubusercontent.com/mr-wolf-gb/AI-Agent-Reset-Tracker/main/assets/data/ai_ides.json
```

Fallback (offline): bundled at `assets/data/ai_ides.json`
