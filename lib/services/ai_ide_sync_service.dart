import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../models/ai_ide.dart';
import 'database_service.dart';

class AiIdeSyncService {
  final DatabaseService _db;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  AiIdeSyncService(this._db);

  Future<bool> sync(String url) async {
    List<dynamic>? jsonList;

    // Try remote source
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          jsonList = data;
        } else if (data is Map && data.containsKey('ides')) {
          jsonList = data['ides'] as List;
        }
      }
    } on DioException catch (_) {
      // Fall through to local asset
    }

    // Fallback to bundled asset
    if (jsonList == null) {
      try {
        final raw =
            await rootBundle.loadString(AppConstants.localAiIdeListPath);
        jsonList = json.decode(raw) as List;
      } catch (_) {
        return false;
      }
    }

    await _processIdes(jsonList);
    return true;
  }

  Future<void> _processIdes(List<dynamic> list) async {
    final masterIds = <String>{};

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final ide = AiIde.fromJson(item);
      masterIds.add(ide.id);

      final existing = _db.getAiIde(ide.id);
      if (existing == null) {
        await _db.saveAiIde(ide);
      } else if (!existing.isCustom) {
        // Update non-custom IDE from master list
        await _db.saveAiIde(ide.copyWith(isCustom: false, isRemoved: false));
      }
      // Custom IDEs are never overwritten
    }

    // Mark IDEs removed from master list
    for (final ide in _db.getAllAiIdes()) {
      if (!ide.isCustom && !masterIds.contains(ide.id) && !ide.isRemoved) {
        await _db.saveAiIde(ide.copyWith(isRemoved: true));
      }
    }
  }
}
