import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../services/ai_ide_sync_service.dart';
import '../services/biometric_service.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

final aiIdeSyncServiceProvider = Provider<AiIdeSyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AiIdeSyncService(db);
});
