import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_ide.dart';
import '../models/account.dart';
import '../models/ide_account_summary.dart';
import '../services/database_service.dart';
import 'service_providers.dart';
import 'account_provider.dart';

class AiIdeNotifier extends StateNotifier<List<AiIde>> {
  AiIdeNotifier(this._db) : super([]) {
    _load();
  }

  final DatabaseService _db;

  void _load() {
    final list = _db.getAllAiIdes();
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> addCustomIde(AiIde ide) async {
    await _db.saveAiIde(ide);
    _load();
  }

  Future<void> updateIde(AiIde ide) async {
    await _db.saveAiIde(ide);
    _load();
  }

  Future<void> deleteCustomIde(String id) async {
    await _db.deleteAiIde(id);
    _load();
  }

  AiIde? getById(String id) => _db.getAiIde(id);

  void reload() => _load();
}

final aiIdeProvider =
    StateNotifierProvider<AiIdeNotifier, List<AiIde>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AiIdeNotifier(db);
});

/// Dashboard summaries — IDEs that have ≥1 account, sorted by urgency
final ideSummariesProvider = Provider<List<IdeAccountSummary>>((ref) {
  final ides = ref.watch(aiIdeProvider);
  final accountsAsync = ref.watch(accountProvider);

  return accountsAsync.when(
    data: (accounts) {
      final byIde = <String, List<Account>>{};
      for (final a in accounts) {
        byIde.putIfAbsent(a.aiIdeId, () => []).add(a);
      }

      final summaries = <IdeAccountSummary>[];
      final knownIds = ides.map((i) => i.id).toSet();

      for (final ide in ides) {
        final ideAccounts = byIde[ide.id];
        if (ideAccounts == null || ideAccounts.isEmpty) continue;
        summaries.add(IdeAccountSummary(ide: ide, accounts: ideAccounts));
      }

      // Accounts for unknown/removed IDEs
      for (final entry in byIde.entries) {
        if (!knownIds.contains(entry.key)) {
          summaries.add(IdeAccountSummary(
            ide: AiIde.unknown(entry.key),
            accounts: entry.value,
          ));
        }
      }

      summaries.sort((a, b) {
        final cmp =
            a.worstStatus.sortOrder.compareTo(b.worstStatus.sortOrder);
        if (cmp != 0) return cmp;
        final an = a.nearestReset;
        final bn = b.nearestReset;
        if (an != null && bn != null) return an.compareTo(bn);
        return a.ide.name.compareTo(b.ide.name);
      });

      return summaries;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
