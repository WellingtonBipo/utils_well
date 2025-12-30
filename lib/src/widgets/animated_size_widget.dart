import 'package:flutter/material.dart';

class AnimatedSizeWidget extends StatefulWidget {
  const AnimatedSizeWidget({
    required this.sizeRatio,
    this.size,
    this.child,
    this.reverseDuration,
    this.scaleChild = false,
    this.axis = .vertical,
    this.axisAlignment = 0,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  });

  final Widget? child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final double axisAlignment;
  final Axis axis;
  final double? size;
  final double sizeRatio;
  final bool scaleChild;

  @override
  State<AnimatedSizeWidget> createState() => _AnimatedSizeWidgetState();
}

class _AnimatedSizeWidgetState extends State<AnimatedSizeWidget>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    value: widget.sizeRatio,
  );

  late final _animation = _controller.drive(CurveTween(curve: widget.curve));

  @override
  void didUpdateWidget(covariant AnimatedSizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sizeRatio == oldWidget.sizeRatio) return;
    _controller.animateTo(widget.sizeRatio);
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    if (child == null && widget.size != null) {
      child = SizedBox(
        width: widget.axis == .horizontal ? widget.size : null,
        height: widget.axis == .vertical ? widget.size : null,
        child: child,
      );
    }
    if (widget.scaleChild) {
      child = ScaleTransition(scale: _animation, child: child);
    }
    return SizeTransition(
      sizeFactor: _animation,
      axis: widget.axis,
      axisAlignment: widget.axisAlignment,
      child: child,
    );
  }
}
