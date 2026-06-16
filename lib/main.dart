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
    final currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));
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

  // Open Hive boxes
  await Hive.openBox<AiIde>('ai_ides');
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<AppSettings>('app_settings');

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: AgentVaultApp(),
    ),
  );
}
