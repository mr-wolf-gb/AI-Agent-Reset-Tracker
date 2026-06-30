import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class UsageLog {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String accountId;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final String action; // 'limit_hit', 'manual_reset'
  @HiveField(4)
  final int? durationHours;

  UsageLog({
    required this.id,
    required this.accountId,
    required this.timestamp,
    required this.action,
    this.durationHours,
  });
}

class UsageLogAdapter extends TypeAdapter<UsageLog> {
  @override
  final int typeId = 3;

  @override
  UsageLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageLog(
      id: fields[0] as String,
      accountId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      action: fields[3] as String,
      durationHours: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UsageLog obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.accountId);
    writer.writeByte(2);
    writer.write(obj.timestamp);
    writer.writeByte(3);
    writer.write(obj.action);
    writer.writeByte(4);
    writer.write(obj.durationHours);
  }
}
