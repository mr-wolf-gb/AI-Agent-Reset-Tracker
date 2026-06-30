import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_ide_provider.dart';
import '../../services/biometric_service.dart';
import '../../providers/service_providers.dart';
import '../../services/ai_ide_sync_service.dart';
import '../../models/app_settings.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _biometricAvailable = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    final bio = BiometricService();
    final available = await bio.isAvailable();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _biometricAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final updateState = ref.watch(updateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Security ---
          _SectionHeader('Security'),
          _SettingsCard(children: [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              subtitle: Text(_biometricAvailable
                  ? 'Require authentication on open'
                  : 'Not available on this device'),
              value: settings.biometricEnabled && _biometricAvailable,
              onChanged: _biometricAvailable
                  ? (v) async {
                      await ref
                          .read(settingsProvider.notifier)
                          .setBiometricEnabled(v);
                      if (v) {
                        ref.read(authProvider.notifier).markAuthenticated();
                      }
                    }
                  : null,
            ),
          ]),
          const SizedBox(height: 16),

          // --- Notifications ---
          _SectionHeader('Notifications'),
          _SettingsCard(children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Reset reminders for tracked accounts'),
              value: settings.notificationsEnabled,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(v),
            ),
            if (settings.notificationsEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Advance Notice'),
                subtitle: Text(
                    '${settings.notificationAdvanceMinutes} min before reset'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickAdvanceTime(settings),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary:
                    const Icon(Icons.do_not_disturb_on_outlined),
                title: const Text('Do Not Disturb'),
                subtitle: Text(
                    '${_fmtHour(settings.doNotDisturbStartHour)} – ${_fmtHour(settings.doNotDisturbEndHour)}'),
                value: settings.doNotDisturbEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setDoNotDisturb(v),
              ),
              if (settings.doNotDisturbEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const SizedBox(width: 24),
                  title: const Text('DND Hours'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickDndHours(settings),
                ),
              ],
            ],
          ]),
          const SizedBox(height: 16),

          // --- Updates ---
          _SectionHeader('Updates'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.system_update_outlined),
              title: const Text('Current Version'),
              trailing: Text(
                'v$_version',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: updateState.isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent))
                  : const Icon(Icons.refresh),
              title: const Text('Check for Updates'),
              subtitle: settings.lastUpdateCheck != null
                  ? Text(
                      'Last checked ${DateFormatter.formatRelative(settings.lastUpdateCheck!)}')
                  : const Text('Never checked'),
              onTap: updateState.isChecking
                  ? null
                  : () async {
                      await ref
                          .read(updateProvider.notifier)
                          .check(_version);
                      if (!mounted) return;
                      final u = ref.read(updateProvider).availableUpdate;
                      if (u != null) {
                        await UpdateDialog.show(context, u);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You are on the latest version!')),
                        );
                      }
                    },
            ),
            if (updateState.availableUpdate != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.new_releases,
                    color: AppColors.accent),
                title: Text(
                  'v${updateState.availableUpdate!.version} available',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600),
                ),
                trailing: TextButton(
                  onPressed: () => UpdateDialog.show(
                      context, updateState.availableUpdate!),
                  child: const Text('Update'),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 16),

          // --- AI IDE Sync ---
          _SectionHeader('AI Tools Sync'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync AI Tools List'),
              subtitle: settings.lastAiIdeSync != null
                  ? Text(
                      'Last synced ${DateFormatter.formatRelative(settings.lastAiIdeSync!)}')
                  : const Text('Never synced'),
              trailing: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent))
                  : const Icon(Icons.chevron_right),
              onTap: _isSyncing ? null : () => _syncAiIdes(settings),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Data Source URL'),
              subtitle: Text(
                settings.aiIdeListUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => _editSyncUrl(settings),
            ),
          ]),
          const SizedBox(height: 16),

          // --- About ---
          _SectionHeader('About'),
          _SettingsCard(children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    AppLogo(size: 56),
                    SizedBox(height: 10),
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppConstants.appTagline,
                      style:
                          TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _syncAiIdes(AppSettings settings) async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(aiIdeSyncServiceProvider);
      final ok = await syncService.sync(settings.aiIdeListUrl);
      ref.read(aiIdeProvider.notifier).reload();
      await ref.read(settingsProvider.notifier).updateLastAiIdeSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'AI tools synced successfully' : 'Sync failed'),
        backgroundColor:
            ok ? AppColors.available : AppColors.needsReset,
      ));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _editSyncUrl(AppSettings settings) async {
    final ctrl = TextEditingController(text: settings.aiIdeListUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Source URL'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'JSON URL',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setAiIdeListUrl(result);
    }
  }

  Future<void> _pickAdvanceTime(AppSettings settings) async {
    const options = [15, 30, 60, 120, 240, 480, 1440];
    const labels = [
      '15 min',
      '30 min',
      '1 hour',
      '2 hours',
      '4 hours',
      '8 hours',
      '1 day'
    ];
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Advance Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (i) {
            return RadioListTile<int>(
              title: Text(labels[i]),
              value: options[i],
              groupValue: settings.notificationAdvanceMinutes,
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setAdvanceMinutes(v);
                }
                Navigator.pop(ctx);
              },
            );
          }),
        ),
      ),
    );
  }

  Future<void> _pickDndHours(AppSettings settings) async {
    int start = settings.doNotDisturbStartHour;
    int end = settings.doNotDisturbEndHour;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do Not Disturb Hours'),
        content: StatefulBuilder(
          builder: (ctx2, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Start: ${_fmtHour(start)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx2,
                    initialTime: TimeOfDay(hour: start, minute: 0),
                  );
                  if (t != null) setLocal(() => start = t.hour);
                },
              ),
              ListTile(
                title: Text('End: ${_fmtHour(end)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx2,
                    initialTime: TimeOfDay(hour: end, minute: 0),
                  );
                  if (t != null) setLocal(() => end = t.hour);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setDoNotDisturbHours(start, end);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _fmtHour(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:00 $period';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
