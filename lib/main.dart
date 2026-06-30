import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'models/ai_ide.dart';
import 'models/account.dart';
import 'models/app_settings.dart';
import 'models/usage_log.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize timezone
  tz.initializeTimeZones();
  try {
    final dynamic timezoneData = await FlutterTimezone.getLocalTimezone();
    String? name;
    if (timezoneData is String) {
      name = timezoneData;
    } else {
      name = timezoneData.identifier;
    }
    if (name != null) {
      tz.setLocalLocation(tz.getLocation(name));
    } else {
      tz.setLocalLocation(tz.UTC);
    }
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }

  // Initialize Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AiIdeAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AppSettingsAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(UsageLogAdapter());

  // Open Hive boxes
  await Hive.openBox<AiIde>('ai_ides');
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<AppSettings>('app_settings');
  await Hive.openBox<UsageLog>('usage_logs');

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: AgentVaultApp(),
    ),
  );
}
