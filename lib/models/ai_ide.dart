import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';

class AiIde {
  final String id;
  final String name;
  final String website;
  final String iconUrl;
  final String type;
  final bool isCustom;
  final bool isRemoved;
  final DateTime updatedAt;
  final String? description;
  final int? resetPeriodHours;
  final List<int>? resetPresets;

  const AiIde({
    required this.id,
    required this.name,
    required this.website,
    required this.iconUrl,
    required this.type,
    this.isCustom = false,
    this.isRemoved = false,
    required this.updatedAt,
    this.description,
    this.resetPeriodHours,
    this.resetPresets,
  });

  factory AiIde.unknown(String id) => AiIde(
        id: id,
        name: 'Unknown AI IDE',
        website: '',
        iconUrl: '',
        type: 'unknown',
        isRemoved: true,
        updatedAt: DateTime.now(),
      );

  factory AiIde.fromJson(Map<String, dynamic> json) => AiIde(
        id: json['id'] as String,
        name: json['name'] as String,
        website: json['website'] as String? ?? '',
        iconUrl: json['icon_url'] as String? ?? '',
        type: json['type'] as String? ?? 'web-app',
        isCustom: json['is_custom'] as bool? ?? false,
        isRemoved: json['is_removed'] as bool? ?? false,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        description: json['description'] as String?,
        resetPeriodHours: json['reset_period_hours'] as int?,
        resetPresets: (json['reset_presets'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'website': website,
        'icon_url': iconUrl,
        'type': type,
        'is_custom': isCustom,
        'is_removed': isRemoved,
        'updated_at': updatedAt.toIso8601String(),
        'description': description,
        'reset_period_hours': resetPeriodHours,
        'reset_presets': resetPresets,
      };

  AiIde copyWith({
    String? id,
    String? name,
    String? website,
    String? iconUrl,
    String? type,
    bool? isCustom,
    bool? isRemoved,
    DateTime? updatedAt,
    String? description,
    int? resetPeriodHours,
    List<int>? resetPresets,
  }) =>
      AiIde(
        id: id ?? this.id,
        name: name ?? this.name,
        website: website ?? this.website,
        iconUrl: iconUrl ?? this.iconUrl,
        type: type ?? this.type,
        isCustom: isCustom ?? this.isCustom,
        isRemoved: isRemoved ?? this.isRemoved,
        updatedAt: updatedAt ?? this.updatedAt,
        description: description ?? this.description,
        resetPeriodHours: resetPeriodHours ?? this.resetPeriodHours,
        resetPresets: resetPresets ?? this.resetPresets,
      );

  String get typeLabel {
    switch (type) {
      case 'desktop-ide':
        return 'Desktop IDE';
      case 'web-app':
        return 'Web App';
      case 'web-ide':
        return 'Web IDE';
      case 'plugin':
        return 'Plugin';
      case 'cli':
        return 'CLI Tool';
      case 'api':
        return 'API';
      default:
        return 'Unknown';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'desktop-ide':
        return AppColors.typeDesktopIde;
      case 'web-app':
        return AppColors.typeWebApp;
      case 'web-ide':
        return AppColors.typeWebIde;
      case 'plugin':
        return AppColors.typePlugin;
      case 'cli':
        return AppColors.typeCli;
      case 'api':
        return AppColors.typeApi;
      default:
        return AppColors.typeUnknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiIde && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AiIdeAdapter extends TypeAdapter<AiIde> {
  @override
  final int typeId = 0;

  @override
  AiIde read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiIde(
      id: fields[0] as String,
      name: fields[1] as String,
      website: fields[2] as String,
      iconUrl: fields[3] as String,
      type: fields[4] as String,
      isCustom: fields[5] as bool? ?? false,
      isRemoved: fields[6] as bool? ?? false,
      updatedAt: fields[7] as DateTime? ?? DateTime.now(),
      description: fields[8] as String?,
      resetPeriodHours: fields[9] as int?,
      resetPresets: (fields[10] as List<dynamic>?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, AiIde obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.website);
    writer.writeByte(3);
    writer.write(obj.iconUrl);
    writer.writeByte(4);
    writer.write(obj.type);
    writer.writeByte(5);
    writer.write(obj.isCustom);
    writer.writeByte(6);
    writer.write(obj.isRemoved);
    writer.writeByte(7);
    writer.write(obj.updatedAt);
    writer.writeByte(8);
    writer.write(obj.description);
    writer.writeByte(9);
    writer.write(obj.resetPeriodHours);
    writer.writeByte(10);
    writer.write(obj.resetPresets);
  }
}
