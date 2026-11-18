import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'theme.dart';

/// A section title with an optional icon and "See all" link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 8, 8),
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(l.seeAll),
              const Icon(Icons.chevron_right, size: 20),
            ]),
          ),
      ]),
    );
  }
}

/// A grey placeholder that gently pulses while its content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, required this.height, this.radius = AppRadius.md});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// An icon on layered soft circles with a few sparkles: a small illustration
/// built from shapes, so it needs no image assets and follows the colour.
class IllustratedBadge extends StatelessWidget {
  const IllustratedBadge({super.key, required this.icon, required this.color, this.size = 72});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget dot(double d, double alpha) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: color.withValues(alpha: alpha), shape: BoxShape.circle),
        );
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          dot(size, 0.12),
          dot(size * 0.72, 0.20),
          Icon(icon, size: size * 0.42, color: color),
          Positioned(top: size * 0.04, right: size * 0.06, child: dot(size * 0.12, 0.45)),
          Positioned(bottom: size * 0.10, left: size * 0.02, child: dot(size * 0.08, 0.35)),
          Positioned(top: size * 0.30, left: 0, child: dot(size * 0.05, 0.5)),
        ]),
      ),
    );
  }
}

/// A small rounded label, e.g. "Required" or "Verified". Always has text, so it
/// never relies on colour alone.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon, this.filled = false});
  final String label;
  final Color color;
  final IconData? icon;

  /// Solid background with white text, for the strongest emphasis.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}

/// An illustrated message for empty lists and dead ends, with an optional
/// action so the person always has a next step.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IllustratedBadge(icon: icon, color: color ?? theme.colorScheme.primary, size: 104),
          const SizedBox(height: 20),
          if (title != null) ...[
            Text(title!, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

/// An InkWell with weight: the content presses in slightly and a light haptic
/// confirms the tap. Use it for every tappable card and row.
class Tap extends StatefulWidget {
  const Tap({super.key, required this.onTap, required this.child, this.borderRadius, this.customBorder, this.scale = 0.97});

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final double scale;

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  var _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        borderRadius: widget.borderRadius,
        customBorder: widget.customBorder,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Fades and rises into place once, staggered by [index].
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + 60 * index.clamp(0, 6)),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
        ),
        child: child,
      );
}
