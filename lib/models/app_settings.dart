import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

class AppSettings {
  bool biometricEnabled;
  bool notificationsEnabled;
  bool doNotDisturbEnabled;
  int doNotDisturbStartHour;
  int doNotDisturbEndHour;
  String notificationSound;
  int notificationAdvanceMinutes;
  DateTime? lastUpdateCheck;
  String? latestAvailableVersion;
  String? updateDownloadUrl;
  String aiIdeListUrl;
  DateTime? lastAiIdeSync;
  bool hasCompletedOnboarding;
  bool appLockEnabled;

  AppSettings({
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStartHour = 22,
    this.doNotDisturbEndHour = 8,
    this.notificationSound = 'default',
    this.notificationAdvanceMinutes = 60,
    this.lastUpdateCheck,
    this.latestAvailableVersion,
    this.updateDownloadUrl,
    String? aiIdeListUrl,
    this.lastAiIdeSync,
    this.hasCompletedOnboarding = false,
    this.appLockEnabled = false,
  }) : aiIdeListUrl = aiIdeListUrl ?? AppConstants.defaultAiIdeListUrl;

  AppSettings copyWith({
    bool? biometricEnabled,
    bool? notificationsEnabled,
    bool? doNotDisturbEnabled,
    int? doNotDisturbStartHour,
    int? doNotDisturbEndHour,
    String? notificationSound,
    int? notificationAdvanceMinutes,
    DateTime? lastUpdateCheck,
    String? latestAvailableVersion,
    String? updateDownloadUrl,
    String? aiIdeListUrl,
    DateTime? lastAiIdeSync,
    bool? hasCompletedOnboarding,
    bool? appLockEnabled,
  }) =>
      AppSettings(
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
        doNotDisturbStartHour:
            doNotDisturbStartHour ?? this.doNotDisturbStartHour,
        doNotDisturbEndHour: doNotDisturbEndHour ?? this.doNotDisturbEndHour,
        notificationSound: notificationSound ?? this.notificationSound,
        notificationAdvanceMinutes:
            notificationAdvanceMinutes ?? this.notificationAdvanceMinutes,
        lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
        latestAvailableVersion:
            latestAvailableVersion ?? this.latestAvailableVersion,
        updateDownloadUrl: updateDownloadUrl ?? this.updateDownloadUrl,
        aiIdeListUrl: aiIdeListUrl ?? this.aiIdeListUrl,
        lastAiIdeSync: lastAiIdeSync ?? this.lastAiIdeSync,
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? this.hasCompletedOnboarding,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      );
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      biometricEnabled: fields[0] as bool? ?? false,
      notificationsEnabled: fields[1] as bool? ?? true,
      doNotDisturbEnabled: fields[2] as bool? ?? false,
      doNotDisturbStartHour: fields[3] as int? ?? 22,
      doNotDisturbEndHour: fields[4] as int? ?? 8,
      notificationSound: fields[5] as String? ?? 'default',
      notificationAdvanceMinutes: fields[6] as int? ?? 60,
      lastUpdateCheck: fields[7] as DateTime?,
      latestAvailableVersion: fields[8] as String?,
      updateDownloadUrl: fields[9] as String?,
      aiIdeListUrl: fields[10] as String?,
      lastAiIdeSync: fields[11] as DateTime?,
      hasCompletedOnboarding: fields[12] as bool? ?? false,
      appLockEnabled: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeByte(14);
    writer.writeByte(0);
    writer.write(obj.biometricEnabled);
    writer.writeByte(1);
    writer.write(obj.notificationsEnabled);
    writer.writeByte(2);
    writer.write(obj.doNotDisturbEnabled);
    writer.writeByte(3);
    writer.write(obj.doNotDisturbStartHour);
    writer.writeByte(4);
    writer.write(obj.doNotDisturbEndHour);
    writer.writeByte(5);
    writer.write(obj.notificationSound);
    writer.writeByte(6);
    writer.write(obj.notificationAdvanceMinutes);
    writer.writeByte(7);
    writer.write(obj.lastUpdateCheck);
    writer.writeByte(8);
    writer.write(obj.latestAvailableVersion);
    writer.writeByte(9);
    writer.write(obj.updateDownloadUrl);
    writer.writeByte(10);
    writer.write(obj.aiIdeListUrl);
    writer.writeByte(11);
    writer.write(obj.lastAiIdeSync);
    writer.writeByte(12);
    writer.write(obj.hasCompletedOnboarding);
    writer.writeByte(13);
    writer.write(obj.appLockEnabled);
  }
}
