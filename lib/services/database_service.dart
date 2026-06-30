import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';
import '../models/ai_ide.dart';
import '../models/account.dart';
import '../models/app_settings.dart';
import '../models/usage_log.dart';


class DatabaseService {
  Box<AiIde> get _aiIdesBox => Hive.box<AiIde>(AppConstants.aiIdesBox);
  Box<Account> get _accountsBox => Hive.box<Account>(AppConstants.accountsBox);
  Box<AppSettings> get _settingsBox =>
      Hive.box<AppSettings>(AppConstants.settingsBox);
  Box<UsageLog> get _usageLogsBox =>
      Hive.box<UsageLog>(AppConstants.usageLogsBox);


  // AiIde CRUD
  List<AiIde> getAllAiIdes() => _aiIdesBox.values.toList();
  AiIde? getAiIde(String id) => _aiIdesBox.get(id);

  Future<void> saveAiIde(AiIde ide) async {
    await _aiIdesBox.put(ide.id, ide);
  }

  Future<void> deleteAiIde(String id) async {
    await _aiIdesBox.delete(id);
  }

  // Account CRUD
  List<Account> getAllAccounts() => _accountsBox.values.toList();

  List<Account> getAccountsForIde(String ideId) =>
      _accountsBox.values.where((a) => a.aiIdeId == ideId).toList();

  Account? getAccount(String id) => _accountsBox.get(id);

  Future<void> saveAccount(Account account) async {
    await _accountsBox.put(account.id, account);
  }

  Future<void> deleteAccount(String id) async {
    await _accountsBox.delete(id);
  }

  // Settings
  AppSettings getSettings() =>
      _settingsBox.get(AppConstants.settingsKey) ?? AppSettings();

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(AppConstants.settingsKey, settings);
  }

  // Usage Logs
  List<UsageLog> getLogsForAccount(String accountId) => _usageLogsBox.values
      .where((l) => l.accountId == accountId)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  Future<void> addUsageLog(UsageLog log) async {
    await _usageLogsBox.put(log.id, log);
  }

  Future<void> deleteLogsForAccount(String accountId) async {
    final keys = _usageLogsBox.keys
        .where((k) => _usageLogsBox.get(k)?.accountId == accountId);
    await _usageLogsBox.deleteAll(keys);
  }
}
