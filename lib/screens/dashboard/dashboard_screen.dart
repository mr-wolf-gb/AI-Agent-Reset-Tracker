import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/ai_ide_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/ide_account_summary.dart';
import '../../models/account.dart';
import '../../widgets/ide_icon.dart';
import '../../widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(ideSummariesProvider);
    final accountsAsync = ref.watch(accountProvider);
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 900 ? 4 : (width > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Account',
            onPressed: () => _showIdePicker(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (summaries.isEmpty) {
            return EmptyState(
              icon: Icons.shield_outlined,
              title: 'No Accounts Yet',
              subtitle: 'Tap + to start tracking your AI tool accounts.',
              actionLabel: 'Add Account',
              onAction: () => _showIdePicker(context, ref),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref.invalidate(accountProvider);
              ref.invalidate(aiIdeProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _IdeSummaryCard(
                        summary: summaries[i],
                        onTap: () =>
                            context.push('/ide/${summaries[i].ide.id}'),
                      ),
                      childCount: summaries.length,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIdePicker(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }

  void _showIdePicker(BuildContext context, WidgetRef ref) {
    final ides = ref.read(aiIdeProvider)
        .where((i) => !i.isRemoved)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select AI Tool',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: ides.length,
                itemBuilder: (_, i) {
                  final ide = ides[i];
                  return ListTile(
                    leading: IdeIcon(ide: ide, size: 36),
                    title: Text(ide.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(ide.typeLabel),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/ide/${ide.id}/add');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeSummaryCard extends StatelessWidget {
  final IdeAccountSummary summary;
  final VoidCallback onTap;

  const _IdeSummaryCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ide = summary.ide;
    final worst = summary.worstStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: worst.color, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IdeIcon(ide: ide, size: 32),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: worst.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                ide.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Status counts
              Row(
                children: [
                  if (summary.availableCount > 0)
                    _CountChip(
                        count: summary.availableCount,
                        color: AppColors.available,
                        bgColor: isDark ? null : AppColors.availableLight,
                        icon: Icons.check_circle),
                  if (summary.resetSoonCount > 0) ...[
                    const SizedBox(width: 4),
                    _CountChip(
                        count: summary.resetSoonCount,
                        color: AppColors.resetSoon,
                        bgColor: isDark ? null : AppColors.resetSoonLight,
                        icon: Icons.schedule),
                  ],
                  if (summary.restrictedCount > 0) ...[
                    const SizedBox(width: 4),
                    _CountChip(
                        count: summary.restrictedCount,
                        color: AppColors.needsReset,
                        bgColor: isDark ? null : AppColors.needsResetLight,
                        icon: Icons.error_outline),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${summary.totalCount} account${summary.totalCount != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textDimLight
                          : AppColors.textTertiary,
                    ),
              ),
              if (summary.nearestReset != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatCountdown(summary.nearestReset!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: worst.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final Color color;
  final Color? bgColor;
  final IconData icon;
  const _CountChip({
    required this.count,
    required this.color,
    this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? (isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
