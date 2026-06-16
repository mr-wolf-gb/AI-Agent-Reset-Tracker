import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/color_constants.dart';

enum AccountStatus { available, resetSoon, needsReset, inactive }

extension AccountStatusX on AccountStatus {
  int get sortOrder {
    switch (this) {
      case AccountStatus.needsReset:
        return 0;
      case AccountStatus.resetSoon:
        return 1;
      case AccountStatus.available:
        return 2;
      case AccountStatus.inactive:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case AccountStatus.needsReset:
        return 'Needs Reset';
      case AccountStatus.resetSoon:
        return 'Resetting Soon';
      case AccountStatus.available:
        return 'Available';
      case AccountStatus.inactive:
        return 'Inactive';
    }
  }

  Color get color {
    switch (this) {
      case AccountStatus.needsReset:
        return AppColors.needsReset;
      case AccountStatus.resetSoon:
        return AppColors.resetSoon;
      case AccountStatus.available:
        return AppColors.available;
      case AccountStatus.inactive:
        return AppColors.inactive;
    }
  }

  IconData get icon {
    switch (this) {
      case AccountStatus.needsReset:
        return Icons.error_outline;
      case AccountStatus.resetSoon:
        return Icons.schedule;
      case AccountStatus.available:
        return Icons.check_circle_outline;
      case AccountStatus.inactive:
        return Icons.pause_circle_outline;
    }
  }
}

class Account {
  final String id;
  final String aiIdeId;
  String email;
  DateTime? resetTime;
  bool isActive;
  bool notificationEnabled;
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;

  Account({
    required this.id,
    required this.aiIdeId,
    required this.email,
    this.resetTime,
    this.isActive = true,
    this.notificationEnabled = true,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get passwordStorageKey => '${AppConstants.accountPasswordPrefix}$id';

  AccountStatus get status {
    if (!isActive) return AccountStatus.inactive;
    if (resetTime == null) return AccountStatus.available;
    final now = DateTime.now();
    if (now.isAfter(resetTime!)) return AccountStatus.needsReset;
    final diff = resetTime!.difference(now);
    if (diff.inHours <= 24) return AccountStatus.resetSoon;
    return AccountStatus.available;
  }

  bool get isAvailable =>
      status == AccountStatus.available || status == AccountStatus.resetSoon;

  Account copyWith({
    String? id,
    String? aiIdeId,
    String? email,
    DateTime? resetTime,
    bool? isActive,
    bool? notificationEnabled,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearResetTime = false,
  }) =>
      Account(
        id: id ?? this.id,
        aiIdeId: aiIdeId ?? this.aiIdeId,
        email: email ?? this.email,
        resetTime: clearResetTime ? null : (resetTime ?? this.resetTime),
        isActive: isActive ?? this.isActive,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Account && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 1;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      aiIdeId: fields[1] as String,
      email: fields[2] as String,
      resetTime: fields[3] as DateTime?,
      isActive: fields[4] as bool? ?? true,
      notificationEnabled: fields[5] as bool? ?? true,
      notes: fields[6] as String? ?? '',
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      updatedAt: fields[8] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.aiIdeId);
    writer.writeByte(2);
    writer.write(obj.email);
    writer.writeByte(3);
    writer.write(obj.resetTime);
    writer.writeByte(4);
    writer.write(obj.isActive);
    writer.writeByte(5);
    writer.write(obj.notificationEnabled);
    writer.writeByte(6);
    writer.write(obj.notes);
    writer.writeByte(7);
    writer.write(obj.createdAt);
    writer.writeByte(8);
    writer.write(obj.updatedAt);
  }
}
