import 'package:flutter/material.dart';

/// A horizontal row of equal-width cards that snaps one card at a time.
///
/// The card in front sits at the left padding; the next one peeks in from the
/// right, faded. Once scrolled, the left edge fades too, so cards dissolve into
/// the page instead of being cut off.
///
/// The fade is a page-coloured gradient painted over the cards. On the plain
/// page background that looks the same as masking the cards, but costs no
/// offscreen layer, so the page scrolls smoothly past the carousel.
class SnapCarousel extends StatefulWidget {
  const SnapCarousel({
    super.key,
    required this.itemWidth,
    required this.gap,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 14),
  });

  final double itemWidth;
  final double gap;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  State<SnapCarousel> createState() => _SnapCarouselState();
}

class _SnapCarouselState extends State<SnapCarousel> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _extent => widget.itemWidth + widget.gap;

  @override
  Widget build(BuildContext context) {
    final items = widget.children;
    final scroller = SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: _SnapPhysics(_extent),
      padding: widget.padding,
      // Every card as tall as the tallest, so long titles or large text grow the row.
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: widget.gap),
            SizedBox(width: widget.itemWidth, child: items[i]),
          ],
        ]),
      ),
    );
    if (items.length < 2) return scroller;

    final page = Theme.of(context).scaffoldBackgroundColor;
    return Stack(children: [
      scroller,
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _EdgeFade(_controller, _extent, page)),
          ),
        ),
      ),
    ]);
  }
}

/// The page colour over each edge: none at rest on that side, up to 85% once
/// a card's width of content lies beyond it. Repaints with the scroll position
/// without rebuilding anything.
class _EdgeFade extends CustomPainter {
  _EdgeFade(this.controller, this.extent, this.page) : super(repaint: controller);
  final ScrollController controller;
  final double extent;
  final Color page;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final pos = controller.hasClients ? controller.position : null;
    final pixels = (pos != null && pos.hasPixels) ? pos.pixels : 0.0;
    final max = (pos != null && pos.hasContentDimensions) ? pos.maxScrollExtent : double.infinity;
    // 0 → no fade, 1 → full fade; each ramps in over the first/last card.
    final left = (pixels / extent).clamp(0.0, 1.0);
    final right = max.isFinite ? ((max - pixels) / extent).clamp(0.0, 1.0) : 1.0;
    if (left == 0 && right == 0) return;
    final fadeW = (56 / size.width).clamp(0.0, 0.4);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            page.withValues(alpha: 0.85 * left),
            page.withValues(alpha: 0),
            page.withValues(alpha: 0),
            page.withValues(alpha: 0.85 * right),
          ],
          stops: [0, fadeW, 1 - fadeW, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_EdgeFade old) => old.page != page || old.extent != extent || old.controller != controller;
}

/// Settles on the nearest card, and flings forward or back by one card.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics(this.extent, {super.parent});
  final double extent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) => _SnapPhysics(extent, parent: buildParent(ancestor));

  double _target(ScrollMetrics position, double velocity) {
    var page = position.pixels / extent;
    if (velocity < -toleranceFor(position).velocity) {
      page -= 0.5;
    } else if (velocity > toleranceFor(position).velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _target(position, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: toleranceFor(position));
  }

  @override
  bool get allowImplicitScrolling => false;
}
