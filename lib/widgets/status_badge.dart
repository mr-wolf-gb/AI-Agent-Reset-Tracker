import 'package:flutter/material.dart';
import '../models/account.dart';

class StatusBadge extends StatelessWidget {
  final AccountStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? status.color.withValues(alpha: 0.15)
            : status.lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? status.color.withValues(alpha: 0.4)
              : status.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 11 : 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
