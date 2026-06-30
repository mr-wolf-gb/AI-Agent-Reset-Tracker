import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/account_provider.dart';
import '../../providers/ai_ide_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/account.dart';
import '../../models/ai_ide.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/ide_icon.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class AccountListScreen extends ConsumerWidget {
  final String ideId;
  const AccountListScreen({super.key, required this.ideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsByIdeProvider(ideId));
    final ide = ref.watch(aiIdeProvider.notifier).getById(ideId) ??
        AiIde.unknown(ideId);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        title: Row(
          children: [
            IdeIcon(ide: ide, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(ide.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_circle_outlined,
              title: 'No Accounts',
              subtitle: 'Add your first ${ide.name} account.',
              actionLabel: 'Add Account',
              onAction: () => context.push('/ide/$ideId/add'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _AccountCard(
                account: accounts[i],
                onTap: () =>
                    context.push('/ide/$ideId/edit/${accounts[i].id}'),
                onDelete: () => _confirmDelete(context, ref, accounts[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ide/$ideId/add'),
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
            'Remove ${account.email}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.needsReset),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(accountProvider.notifier).deleteAccount(account.id);
    }
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _showPassword = false;
  String? _password;
  bool _loadingPw = false;

  Future<void> _togglePassword() async {
    if (_showPassword) {
      setState(() {
        _showPassword = false;
        _password = null;
      });
      return;
    }
    setState(() => _loadingPw = true);
    final pw = await ref
        .read(accountProvider.notifier)
        .getPassword(widget.account.id);
    setState(() {
      _password = pw;
      _showPassword = true;
      _loadingPw = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.email,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, size: 20),
                    onPressed: () => _showHistory(context, ref),
                    tooltip: 'Usage History',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 4),
                  StatusBadge(status: account.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              // Password row
              Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _showPassword
                          ? (_password ?? '••••••••')
                          : '••••••••',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.textDimLight
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  if (_loadingPw)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent),
                    )
                  else
                    GestureDetector(
                      onTap: _togglePassword,
                      child: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              if (account.resetTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: account.status.color),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatCountdown(account.resetTime!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: account.status.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormatter.formatDateTime(account.resetTime!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textDimLight
                                  : AppColors.textTertiary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (account.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.notes,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        account.notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textDimLight
                                  : AppColors.textTertiary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!account.isActive)
                    _TagChip(label: 'Inactive', color: AppColors.inactive)
                  else if (account.status == AccountStatus.available)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _markRestricted(context, ref),
                          icon: const Icon(Icons.timer_outlined, size: 14),
                          label: const Text('Hit Limit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            minimumSize: const Size(0, 32),
                            backgroundColor: AppColors.needsReset,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _copyAndLaunch(context, ref),
                          icon: const Icon(Icons.rocket_launch, size: 16),
                          tooltip: 'Copy Email & Open Site',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                            foregroundColor: AppColors.accent,
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(accountProvider.notifier)
                          .clearRestriction(account.id),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Reset Now'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        minimumSize: const Size(0, 32),
                        side: const BorderSide(color: AppColors.available),
                        foregroundColor: AppColors.available,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (account.notificationEnabled)
                    _TagChip(label: 'Alerts On', color: AppColors.accent),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.needsReset),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyAndLaunch(BuildContext context, WidgetRef ref) async {
    final ide = ref.read(aiIdeProvider.notifier).getById(widget.account.aiIdeId);
    if (ide == null) return;

    // Copy email
    await Clipboard.setData(ClipboardData(text: widget.account.email));

    if (!context.mounted) return;

    // Show snackbar with copy password option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email copied! Launching website...'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Copy PW',
          onPressed: () async {
            final pw = await ref
                .read(accountProvider.notifier)
                .getPassword(widget.account.id);
            if (pw != null) {
              await Clipboard.setData(ClipboardData(text: pw));
            }
          },
        ),
      ),
    );

    // Launch URL
    if (ide.website.isNotEmpty) {
      final uri = Uri.parse(ide.website);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    final logs = ref
        .read(accountProvider.notifier)
        .getAccountLogs(widget.account.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Usage History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              widget.account.email,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No history recorded yet.'),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        log.action == 'limit_hit'
                            ? Icons.timer_outlined
                            : Icons.refresh,
                        color: log.action == 'limit_hit'
                            ? AppColors.needsReset
                            : AppColors.available,
                      ),
                      title: Text(log.action == 'limit_hit'
                          ? 'Limit Hit (${log.durationHours}h reset)'
                          : 'Manual Reset'),
                      subtitle: Text(
                        DateFormatter.formatDateTime(log.timestamp),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRestricted(BuildContext context, WidgetRef ref) async {
    final ide = ref.read(aiIdeProvider.notifier).getById(widget.account.aiIdeId);
    if (ide == null) return;

    int? hours = ide.resetPeriodHours;

    // If there are multiple presets or no default, show picker
    if (ide.resetPresets != null && ide.resetPresets!.isNotEmpty) {
      hours = await _showPresetPicker(context, ide.resetPresets!);
      if (hours == null) return;
    } else if (hours == null) {
      hours = await _showResetPeriodPicker(context);
      if (hours == null) return;

      // Update IDE with default reset period
      final updatedIde = ide.copyWith(resetPeriodHours: hours);
      await ref.read(aiIdeProvider.notifier).updateIde(updatedIde);
    }

    final settings = ref.read(settingsProvider);
    await ref.read(accountProvider.notifier).markAsRestricted(
          widget.account.id,
          ref.read(aiIdeProvider.notifier).getById(widget.account.aiIdeId)!,
          duration: Duration(hours: hours),
          advanceMinutes: settings.notificationAdvanceMinutes,
        );
  }

  Future<int?> _showPresetPicker(BuildContext context, List<int> presets) async {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Limit Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: presets.map((h) {
                final label = h >= 24 ? '${h ~/ 24}d' : '${h}h';
                return ChoiceChip(
                  label: Text(label),
                  selected: false,
                  onSelected: (_) => Navigator.pop(ctx, h),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Custom duration...'),
              onTap: () async {
                final custom = await _showResetPeriodPicker(context);
                if (ctx.mounted) Navigator.pop(ctx, custom);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showResetPeriodPicker(BuildContext context) async {
    int selectedHours = 24;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long until this tool resets its limit?'),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (ctx, setState) => Column(
                children: [
                  DropdownButton<int>(
                    value: selectedHours,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Hour')),
                      DropdownMenuItem(value: 3, child: Text('3 Hours')),
                      DropdownMenuItem(value: 6, child: Text('6 Hours')),
                      DropdownMenuItem(value: 12, child: Text('12 Hours')),
                      DropdownMenuItem(value: 24, child: Text('24 Hours (1 Day)')),
                      DropdownMenuItem(value: 48, child: Text('48 Hours (2 Days)')),
                      DropdownMenuItem(value: 168, child: Text('1 Week')),
                      DropdownMenuItem(value: 720, child: Text('30 Days')),
                    ],
                    onChanged: (v) => setState(() => selectedHours = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selectedHours),
            child: const Text('Set Default'),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
