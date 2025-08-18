import 'dart:math' as m;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sliver_tools/sliver_tools.dart' as s;

class SliverPinnedExpandable extends StatefulWidget {
  const SliverPinnedExpandable({
    required this.headerBuilder,
    required this.contentBuilder,
    this.margin = EdgeInsets.zero,
    this.duration = const Duration(milliseconds: 300),
    this.decoration = const ContainerDecoration(),
    super.key,
  });

  final EdgeInsets margin;
  final Duration duration;
  final ContainerDecoration decoration;

  final Widget Function(
    BuildContext context,
    AnimationController expandedController,
  ) headerBuilder;

  final Widget Function(
    BuildContext context,
    AnimationController expandedController,
  ) contentBuilder;

  @override
  State<SliverPinnedExpandable> createState() => _SliverPinnedExpandableState();
}

class _SliverPinnedExpandableState extends State<SliverPinnedExpandable>
    with SingleTickerProviderStateMixin {
  late final _expandedController = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void dispose() {
    _expandedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BoxBorder? border(ContainerDecoration decoration, bool header) {
      if (decoration.borderColor == null) return null;
      final sd = BorderSide(
        color: decoration.borderColor!,
        width: decoration.borderStroke,
      );
      return Border(
        top: header ? sd : BorderSide.none,
        left: sd,
        right: sd,
        bottom: header ? BorderSide.none : sd,
      );
    }

    return SliverPadding(
      padding: widget.margin.copyWith(top: 0),
      sliver: s.SliverStack(
        insetOnOverlap: true,
        children: [
          s.MultiSliver(
            children: [
              PinnedHeaderSliver(
                child: Container(
                  padding: EdgeInsets.only(top: widget.margin.top),
                  decoration: BoxDecoration(
                      color: widget.decoration.outsideBackgroundColor),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.decoration.backgroundColor,
                      border: border(widget.decoration, true),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.decoration.borderRadius),
                      ),
                    ),
                    child: widget.headerBuilder(context, _expandedController),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizeTransition(
                  sizeFactor: _expandedController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.decoration.backgroundColor,
                      border: border(widget.decoration, false),
                    ),
                    child: widget.contentBuilder(context, _expandedController),
                  ),
                ),
              ),
            ],
          ),
          if (widget.decoration.borderRadius > 0)
            s.SliverPositioned(
              height: widget.decoration.borderRadius,
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(painter: _CustomPainter(widget.decoration)),
            ),
        ],
      ),
    );
  }
}

class ContainerDecoration {
  const ContainerDecoration({
    this.backgroundColor,
    this.outsideBackgroundColor,
    this.borderColor,
    this.borderRadius = 0,
    this.borderStroke = 1,
  });

  final Color? borderColor;
  final double borderRadius;
  final double borderStroke;
  final Color? backgroundColor;
  final Color? outsideBackgroundColor;
}

class _CustomPainter extends CustomPainter {
  _CustomPainter(this.decoration);

  final ContainerDecoration decoration;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  late Rect rect;

  late Rect leftBoarder = Rect.fromCircle(
    center: Offset(decoration.borderRadius, 0),
    radius: decoration.borderRadius,
  );

  late Rect rightBoarder = Rect.fromCircle(
    center: Offset(rect.width - decoration.borderRadius, 0),
    radius: decoration.borderRadius,
  );

  @override
  void paint(Canvas canvas, Size size) {
    rect = Rect.fromPoints(
      size.topLeft(Offset.zero),
      size.bottomRight(Offset.zero),
    );
    _removeHeaderBorder(canvas, size);
    _drawBottomBorder(canvas, size);
  }

  void _removeHeaderBorder(Canvas canvas, Size size) {
    final outsideBackgroundColor = decoration.outsideBackgroundColor;
    if (outsideBackgroundColor == null) return;

    final paint = Paint()
      ..color = outsideBackgroundColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..addArc(leftBoarder, m.pi, -m.pi / 2)
      ..lineTo(0, rect.height)
      ..lineTo(0, 0);

    path
      ..moveTo(rect.width - 8, rect.height)
      ..addArc(rightBoarder, m.pi / 2, -m.pi / 2)
      ..lineTo(rect.width, rect.height)
      ..lineTo(rect.width - 8, rect.height);

    canvas.drawPath(path, paint);
  }

  void _drawBottomBorder(Canvas canvas, Size size) {
    final borderColor = decoration.borderColor;
    if (borderColor == null) return;

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = decoration.borderStroke;

    final path = Path()
      ..addArc(leftBoarder.translate(0.5, -.05), m.pi, -m.pi / 2)
      ..lineTo(rect.width - decoration.borderRadius, rect.height - 0.5)
      ..addArc(rightBoarder.translate(-0.5, -.05), m.pi / 2, -m.pi / 2);

    canvas.drawPath(path, paint);
  }
}
