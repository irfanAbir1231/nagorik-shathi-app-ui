import 'package:flutter/material.dart';

import 'theme.dart';

/// The brand header: a green gradient with a rising sun over soft hills and
/// rounded bottom corners. Used by Home and the sign-in screens.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.child, this.radius = AppRadius.xl});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryBright],
            ),
          ),
          child: Stack(children: [
            const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: _HeroPainter()))),
            child,
          ]),
        ),
      );
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sunCentre = Offset(w * 0.66, h * 0.20);
    canvas.drawCircle(sunCentre, 52, Paint()..color = AppColors.sun.withValues(alpha: 0.10));
    canvas.drawCircle(sunCentre, 36, Paint()..color = AppColors.sun.withValues(alpha: 0.18));
    canvas.drawCircle(sunCentre, 20, Paint()..color = AppColors.sun.withValues(alpha: 0.85));

    final back = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.62, h * 0.60)
      ..quadraticBezierTo(w * 0.85, h * 0.72, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = Colors.white.withValues(alpha: 0.06));

    final front = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.22, h * 0.66, w * 0.48, h * 0.78)
      ..quadraticBezierTo(w * 0.78, h * 0.92, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = Colors.white.withValues(alpha: 0.08));

    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.12, h * 0.12), 2.5, sparkle);
    canvas.drawCircle(Offset(w * 0.42, h * 0.08), 1.8, sparkle);
    canvas.drawCircle(Offset(w * 0.86, h * 0.36), 2.2, sparkle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
