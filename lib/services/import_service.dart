import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import 'database_service.dart';

class ImportService {
  final DatabaseService _db;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _uuid = const Uuid();

  ImportService(this._db);

  Future<int> importFromJson(String content) async {
    final data = jsonDecode(content);
    if (data is List) {
      return _importList(data);
    } else if (data is Map) {
      // Support if the JSON is wrapped in an object like { "accounts": [...] }
      final List? list = data['accounts'] ?? data['data'];
      if (list != null) return _importList(list);
    }
    return 0;
  }

  Future<int> importFromCsv(String content) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      content,
      shouldParseNumbers: false,
    );
    if (rows.isEmpty) return 0;

    final headers =
        rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
    final List<Map<String, dynamic>> data = [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final Map<String, dynamic> item = {};
      for (var j = 0; j < headers.length; j++) {
        if (j < row.length) {
          item[headers[j]] = row[j];
        }
      }
      data.add(item);
    }
    return _importList(data);
  }

  Future<int> importFromXml(String content) async {
    try {
      final document = XmlDocument.parse(content);
      // Try finding <account> tags first, then any child of root if root is <accounts>
      var accountNodes = document.findAllElements('account');
      if (accountNodes.isEmpty && document.rootElement.children.isNotEmpty) {
         accountNodes = document.rootElement.childElements;
      }
      
      final List<Map<String, dynamic>> data = [];

      for (var node in accountNodes) {
        final Map<String, dynamic> item = {};
        for (var element in node.childElements) {
          item[element.name.local.toLowerCase()] = element.innerText;
        }
        if (item.isNotEmpty) data.add(item);
      }
      return _importList(data);
    } catch (e) {
      return 0;
    }
  }

  Future<int> _importList(List<dynamic> data) async {
    int importedCount = 0;
    final now = DateTime.now();

    for (var item in data) {
      if (item is! Map) continue;

      // Map common field names
      final email = _getField(item, ['email', 'user', 'username']);
      final aiIdeId = _getField(item, ['ai_ide_id', 'ide_id', 'ide', 'ai_ide', 'type']);

      if (email == null || aiIdeId == null) continue;

      // Validate IDE exists or use a default if possible (though better to skip if invalid)
      final ide = _db.getAiIde(aiIdeId);
      if (ide == null) continue;

      final account = Account(
        id: _uuid.v4(),
        aiIdeId: aiIdeId,
        email: email,
        notes: _getField(item, ['notes', 'description', 'comment']) ?? '',
        isActive: _getBool(item, ['is_active', 'active', 'enabled'], true),
        notificationEnabled: _getBool(item, ['notification_enabled', 'notify'], true),
        createdAt: now,
        updatedAt: now,
      );

      await _db.saveAccount(account);
      importedCount++;
    }
    return importedCount;
  }

  String? _getField(Map item, List<String> keys) {
    for (var key in keys) {
      final val = item[key] ?? item[key.replaceAll('_', '')] ?? item[key.toUpperCase()];
      if (val != null) return val.toString().trim();
    }
    return null;
  }

  bool _getBool(Map item, List<String> keys, bool defaultValue) {
    final val = _getField(item, keys);
    if (val == null) return defaultValue;
    final lower = val.toLowerCase();
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    return defaultValue;
  }

  Future<String?> fetchFromUrl(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return response.data.toString();
      }
    } catch (e) {
      // Log error or handle
    }
    return null;
  }
}
