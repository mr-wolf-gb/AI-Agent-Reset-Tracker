import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';
import 'service_providers.dart';
import 'settings_provider.dart';

class UpdateState {
  final bool isChecking;
  final UpdateInfo? availableUpdate;
  final bool isDownloading;
  final double downloadProgress;
  final String? error;

  const UpdateState({
    this.isChecking = false,
    this.availableUpdate,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.error,
  });

  UpdateState copyWith({
    bool? isChecking,
    UpdateInfo? availableUpdate,
    bool clearUpdate = false,
    bool? isDownloading,
    double? downloadProgress,
    String? error,
  }) =>
      UpdateState(
        isChecking: isChecking ?? this.isChecking,
        availableUpdate:
            clearUpdate ? null : (availableUpdate ?? this.availableUpdate),
        isDownloading: isDownloading ?? this.isDownloading,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        error: error,
      );
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier(this._service, this._settings) : super(const UpdateState());

  final UpdateService _service;
  final SettingsNotifier _settings;

  Future<void> check(String currentVersion) async {
    state = state.copyWith(isChecking: true, error: null);
    try {
      final info = await _service.checkForUpdate(currentVersion);
      await _settings.updateLastUpdateCheck(
        version: info?.version,
        downloadUrl: info?.apkDownloadUrl,
      );
      state = state.copyWith(isChecking: false, availableUpdate: info);
    } catch (e) {
      state = state.copyWith(isChecking: false, error: e.toString());
    }
  }

  Future<void> downloadAndInstall() async {
    final update = state.availableUpdate;
    if (update?.apkDownloadUrl == null) return;
    state = state.copyWith(isDownloading: true, downloadProgress: 0);
    try {
      final path = await _service.downloadApk(
        update!.apkDownloadUrl!,
        onProgress: (recv, total) {
          if (total > 0) {
            state = state.copyWith(downloadProgress: recv / total);
          }
        },
      );
      state = state.copyWith(isDownloading: false);
      await OpenFilex.open(path);
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
    }
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  final settings = ref.read(settingsProvider.notifier);
  return UpdateNotifier(service, settings);
});
