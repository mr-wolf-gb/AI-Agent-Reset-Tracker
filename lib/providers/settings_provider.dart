import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import 'service_providers.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._db) : super(AppSettings()) {
    state = _db.getSettings();
  }

  final DatabaseService _db;

  Future<void> update(AppSettings settings) async {
    await _db.saveSettings(settings);
    state = settings;
  }

  Future<void> setBiometricEnabled(bool v) =>
      update(state.copyWith(biometricEnabled: v));

  Future<void> setNotificationsEnabled(bool v) =>
      update(state.copyWith(notificationsEnabled: v));

  Future<void> setDoNotDisturb(bool v) =>
      update(state.copyWith(doNotDisturbEnabled: v));

  Future<void> setDoNotDisturbHours(int start, int end) =>
      update(state.copyWith(
          doNotDisturbStartHour: start, doNotDisturbEndHour: end));

  Future<void> setAdvanceMinutes(int min) =>
      update(state.copyWith(notificationAdvanceMinutes: min));

  Future<void> setAiIdeListUrl(String url) =>
      update(state.copyWith(aiIdeListUrl: url));

  Future<void> setOnboardingComplete() =>
      update(state.copyWith(hasCompletedOnboarding: true));

  Future<void> setAppLockEnabled(bool v) =>
      update(state.copyWith(appLockEnabled: v));

  Future<void> updateLastUpdateCheck({
    String? version,
    String? downloadUrl,
  }) =>
      update(state.copyWith(
        lastUpdateCheck: DateTime.now(),
        latestAvailableVersion: version,
        updateDownloadUrl: downloadUrl,
      ));

  Future<void> updateLastAiIdeSync() =>
      update(state.copyWith(lastAiIdeSync: DateTime.now()));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SettingsNotifier(db);
});
