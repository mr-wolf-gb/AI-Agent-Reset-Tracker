import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../providers/ai_ide_provider.dart';
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
                    _TagChip(label: 'Inactive', color: AppColors.inactive),
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
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
