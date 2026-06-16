import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
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
    _load();
  }

  Future<String?> getPassword(String accountId) =>
      _secure.getPassword(accountId);

  List<Account> getForIde(String ideId) => _db.getAccountsForIde(ideId);
  Account? getById(String id) => _db.getAccount(id);

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
