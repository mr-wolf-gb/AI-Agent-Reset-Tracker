import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(color: c)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shield shape
    final shield = Path()
      ..moveTo(s * 0.5, 0)
      ..lineTo(s * 0.95, s * 0.2)
      ..lineTo(s * 0.95, s * 0.55)
      ..quadraticBezierTo(s * 0.95, s * 0.85, s * 0.5, s)
      ..quadraticBezierTo(s * 0.05, s * 0.85, s * 0.05, s * 0.55)
      ..lineTo(s * 0.05, s * 0.2)
      ..close();
    canvas.drawPath(shield, paint);

    // White key
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Key circle
    canvas.drawCircle(Offset(s * 0.5, s * 0.42), s * 0.14, white);

    // Key stem
    final stem = Path()
      ..moveTo(s * 0.44, s * 0.52)
      ..lineTo(s * 0.44, s * 0.72)
      ..lineTo(s * 0.5, s * 0.72)
      ..lineTo(s * 0.5, s * 0.66)
      ..lineTo(s * 0.56, s * 0.66)
      ..lineTo(s * 0.56, s * 0.60)
      ..lineTo(s * 0.5, s * 0.60)
      ..lineTo(s * 0.5, s * 0.52)
      ..close();
    canvas.drawPath(stem, white);

    // Key circle hole
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.42),
      s * 0.07,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
