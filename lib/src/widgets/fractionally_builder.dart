import 'package:flutter/widgets.dart';

class FractionallyBuilder extends StatefulWidget {
  const FractionallyBuilder({
    required this.value,
    required this.builder,
    this.child,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  });

  final double value;
  final Widget? child;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;

  @override
  State<FractionallyBuilder> createState() => _FractionallyBuilder();
}

class _FractionallyBuilder extends State<FractionallyBuilder>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    value: widget.value,
  );

  late final _animation = _controller.drive(CurveTween(curve: widget.curve));

  @override
  void didUpdateWidget(covariant FractionallyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    _controller.animateTo(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => widget.builder(context, _animation.value),
    );
  }
}
