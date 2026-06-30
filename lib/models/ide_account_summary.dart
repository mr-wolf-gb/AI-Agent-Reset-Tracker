import 'ai_ide.dart';
import 'account.dart';

class IdeAccountSummary {
  final AiIde ide;
  final List<Account> accounts;

  const IdeAccountSummary({required this.ide, required this.accounts});

  AccountStatus get worstStatus {
    if (accounts.isEmpty) return AccountStatus.inactive;
    AccountStatus worst = AccountStatus.inactive;
    for (final a in accounts) {
      if (a.status.sortOrder < worst.sortOrder) worst = a.status;
    }
    return worst;
  }

  DateTime? get nearestReset {
    DateTime? nearest;
    final now = DateTime.now();
    for (final a in accounts) {
      if (a.resetTime != null && a.resetTime!.isAfter(now)) {
        if (nearest == null || a.resetTime!.isBefore(nearest)) {
          nearest = a.resetTime;
        }
      }
    }
    return nearest;
  }

  int get availableCount =>
      accounts.where((a) => a.status == AccountStatus.available).length;
  int get resetSoonCount =>
      accounts.where((a) => a.status == AccountStatus.resetSoon).length;
  int get restrictedCount =>
      accounts.where((a) => a.status == AccountStatus.restricted).length;
  int get inactiveCount =>
      accounts.where((a) => a.status == AccountStatus.inactive).length;
  int get totalCount => accounts.length;
}
