import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../models/update_info.dart';

class UpdateService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final response = await _dio.get(
        AppConstants.githubReleasesApiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').trim();
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (!_isNewer(latestVersion, currentVersion)) return null;

      final assets = data['assets'] as List<dynamic>? ?? [];
      String? apkUrl;
      String? ipaUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        final url = asset['browser_download_url'] as String? ?? '';
        if (name.endsWith('.apk')) apkUrl = url;
        if (name.endsWith('.ipa')) ipaUrl = url;
      }

      return UpdateInfo(
        version: latestVersion,
        tagName: tagName,
        releaseNotes: data['body'] as String? ?? 'See GitHub for details.',
        apkDownloadUrl: apkUrl,
        ipaDownloadUrl: ipaUrl,
        publishedAt: data['published_at'] as String? ?? '',
      );
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  Future<String> downloadApk(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/AgentVault_update.apk';
    await _dio.download(url, savePath, onReceiveProgress: onProgress);
    return savePath;
  }
}
