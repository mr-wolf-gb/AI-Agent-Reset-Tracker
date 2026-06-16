import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../models/account.dart';
import '../models/ai_ide.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings, onDidReceiveNotificationResponse: _onTap);

    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onTap(NotificationResponse response) {
    // payload: 'accountId:ideId' - hook into router via global navigator key
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleResetNotification({
    required Account account,
    required AiIde ide,
    required int advanceMinutes,
  }) async {
    if (account.resetTime == null) return;
    final notifyAt =
        account.resetTime!.subtract(Duration(minutes: advanceMinutes));
    if (notifyAt.isBefore(DateTime.now())) return;

    final timeStr = DateFormat.jm().format(account.resetTime!);
    final advLabel = advanceMinutes >= 60
        ? '${advanceMinutes ~/ 60}h'
        : '${advanceMinutes}m';

    await _plugin.zonedSchedule(
      account.id.hashCode.abs(),
      '${ide.name} resets in $advLabel',
      '${account.email} resets at $timeStr — get ready!',
      tz.TZDateTime.from(notifyAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${account.id}:${account.aiIdeId}',
    );
  }

  Future<void> cancelNotification(String accountId) async {
    await _plugin.cancel(accountId.hashCode.abs());
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAll({
    required List<Account> accounts,
    required Map<String, AiIde> ideMap,
    required int advanceMinutes,
  }) async {
    await cancelAll();
    for (final account in accounts) {
      if (!account.notificationEnabled) continue;
      final ide = ideMap[account.aiIdeId];
      if (ide == null || ide.isRemoved) continue;
      await scheduleResetNotification(
        account: account,
        ide: ide,
        advanceMinutes: advanceMinutes,
      );
    }
  }
}
