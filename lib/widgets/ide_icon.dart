import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ai_ide.dart';
import '../core/constants/color_constants.dart';

class IdeIcon extends StatelessWidget {
  final AiIde ide;
  final double size;

  const IdeIcon({super.key, required this.ide, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (ide.iconUrl.isEmpty || ide.isRemoved && ide.iconUrl.isEmpty) {
      return _FallbackIcon(ide: ide, size: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: ide.iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (ctx, url, err) => _FallbackIcon(ide: ide, size: size),
        placeholder: (ctx, url) => _FallbackIcon(ide: ide, size: size),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final AiIde ide;
  final double size;
  const _FallbackIcon({required this.ide, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = ide.isRemoved ? AppColors.unknown : ide.typeColor;
    final letter = ide.name.isNotEmpty ? ide.name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
