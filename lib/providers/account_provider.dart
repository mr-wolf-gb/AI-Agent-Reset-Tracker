import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../models/ai_ide.dart';
import '../models/usage_log.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import 'service_providers.dart';

class AccountNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  AccountNotifier(this._db, this._secure) : super(const AsyncValue.loading()) {
    _load();
  }

  final DatabaseService _db;
  final SecureStorageService _secure;

  void _load() {
    state = AsyncValue.data(_db.getAllAccounts());
  }

  Future<void> addAccount(Account account, String password) async {
    await _secure.savePassword(account.id, password);
    await _db.saveAccount(account);
    _load();
  }

  Future<void> updateAccount(Account account, {String? newPassword}) async {
    if (newPassword != null && newPassword.isNotEmpty) {
      await _secure.savePassword(account.id, newPassword);
    }
    account.updatedAt = DateTime.now();
    await _db.saveAccount(account);
    _load();
  }

  Future<void> deleteAccount(String accountId) async {
    await _secure.deletePassword(accountId);
    await _db.deleteAccount(accountId);
    await _db.deleteLogsForAccount(accountId);
    _load();
  }

  Future<String?> getPassword(String accountId) =>
      _secure.getPassword(accountId);

  Future<void> markAsRestricted(String accountId, AiIde ide,
      {Duration? duration, int advanceMinutes = 0}) async {
    final account = getById(accountId);
    if (account == null) return;

    final resetDuration =
        duration ?? Duration(hours: ide.resetPeriodHours ?? 24);
    final resetTime = DateTime.now().add(resetDuration);
    final updated = account.copyWith(
      resetTime: resetTime,
      updatedAt: DateTime.now(),
    );
    await updateAccount(updated);

    // Record Log
    await _db.addUsageLog(UsageLog(
      id: const Uuid().v4(),
      accountId: accountId,
      timestamp: DateTime.now(),
      action: 'limit_hit',
      durationHours: resetDuration.inHours,
    ));

    // Schedule notification
    if (updated.notificationEnabled) {
      await NotificationService.instance.cancelNotification(updated.id);
      await NotificationService.instance.scheduleResetNotification(
        account: updated,
        ide: ide,
        advanceMinutes: advanceMinutes,
      );
    }
  }

  Future<void> clearRestriction(String accountId) async {
    final account = getById(accountId);
    if (account == null) return;

    final updated = account.copyWith(
      clearResetTime: true,
      updatedAt: DateTime.now(),
    );
    await updateAccount(updated);
    await NotificationService.instance.cancelNotification(accountId);

    // Record Log
    await _db.addUsageLog(UsageLog(
      id: const Uuid().v4(),
      accountId: accountId,
      timestamp: DateTime.now(),
      action: 'manual_reset',
    ));
  }

  List<Account> getForIde(String ideId) => _db.getAccountsForIde(ideId);
  Account? getById(String id) => _db.getAccount(id);
  List<UsageLog> getAccountLogs(String accountId) =>
      _db.getLogsForAccount(accountId);

  void reload() => _load();
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<List<Account>>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final secure = ref.watch(secureStorageServiceProvider);
  return AccountNotifier(db, secure);
});

final accountsByIdeProvider =
    Provider.family<List<Account>, String>((ref, ideId) {
  final accounts = ref.watch(accountProvider);
  return accounts.when(
    data: (list) {
      final filtered = list.where((a) => a.aiIdeId == ideId).toList();
      filtered.sort((a, b) {
        final cmp = a.status.sortOrder.compareTo(b.status.sortOrder);
        if (cmp != 0) return cmp;
        if (a.resetTime != null && b.resetTime != null) {
          return a.resetTime!.compareTo(b.resetTime!);
        }
        return 0;
      });
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
