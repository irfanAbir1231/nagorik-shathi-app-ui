import 'package:flutter/material.dart';

import 'theme.dart';

/// The brand header: a green gradient with a rising sun over soft hills and
/// rounded bottom corners. Used by Home and the sign-in screens.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
  });
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
    child: DecoratedBox(
      position: DecorationPosition.background,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.primaryBright,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _HeroPainter()),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

/// The gradient and shapes behind an app bar, so every screen top matches.
class AppBarBackdrop extends StatelessWidget {
  const AppBarBackdrop({super.key});

  @override
  Widget build(BuildContext context) =>
      const HeroBackdrop(radius: AppRadius.lg, child: SizedBox.expand());
}

/// Layered circles, concentric rings, a dotted grid and soft waves, with a warm
/// glow in one corner. Drawn in proportion to the box so it scales with the header.
class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Large soft discs.
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.05),
      h * 0.95,
      Paint()..color = AppColors.mist.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      Offset(w * 0.05, h * 1.05),
      h * 0.8,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    // Warm glow.
    final glowCentre = Offset(w * 0.84, h * 0.22);
    final glowRadius = h * 0.75 < 120 ? 120.0 : h * 0.75;
    canvas.drawCircle(
      glowCentre,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.sun.withValues(alpha: 0.55),
            AppColors.sun.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCentre, radius: glowRadius)),
    );

    // Concentric rings around the glow.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.16);
    for (final r in [38.0, 62.0, 90.0]) {
      canvas.drawCircle(glowCentre, r, ring);
    }

    // Dotted grid, fading toward the right.
    final dot = Paint();
    const gap = 14.0;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 7; col++) {
        dot.color = Colors.white.withValues(alpha: 0.22 - col * 0.025);
        canvas.drawCircle(
          Offset(18 + col * gap, h * 0.30 + row * gap),
          1.6,
          dot,
        );
      }
    }

    // Waves along the bottom.
    final back = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.28, h * 0.52, w * 0.58, h * 0.68)
      ..quadraticBezierTo(w * 0.84, h * 0.80, w, h * 0.60)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      back,
      Paint()..color = AppColors.teal.withValues(alpha: 0.16),
    );

    final front = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.24, h * 0.74, w * 0.5, h * 0.84)
      ..quadraticBezierTo(w * 0.78, h * 0.96, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      front,
      Paint()..color = AppColors.lime.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
