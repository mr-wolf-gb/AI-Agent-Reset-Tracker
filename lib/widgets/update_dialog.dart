import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/update_provider.dart';
import '../models/update_info.dart';
import '../core/constants/color_constants.dart';

class UpdateDialog extends ConsumerWidget {
  final UpdateInfo update;
  const UpdateDialog({super.key, required this.update});

  static Future<void> show(BuildContext context, UpdateInfo update) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(update: update),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AgentVault v${update.version} is ready.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (update.releaseNotes.isNotEmpty) ...[
            Text(
              update.releaseNotes.length > 200
                  ? '${update.releaseNotes.substring(0, 200)}...'
                  : update.releaseNotes,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
          if (updateState.isDownloading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Downloading...'),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: updateState.downloadProgress,
                  backgroundColor: AppColors.borderLight,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.accent),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(updateState.downloadProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              updateState.isDownloading ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        if (Platform.isAndroid && update.apkDownloadUrl != null)
          ElevatedButton(
            onPressed: updateState.isDownloading
                ? null
                : () {
                    ref.read(updateProvider.notifier).downloadAndInstall();
                  },
            child: const Text('Update Now'),
          )
        else
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
      ],
    );
  }
}
