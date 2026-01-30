import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FractionallyBuilder extends StatefulWidget {
  const FractionallyBuilder({
    required double this.value,
    required this.builder,
    this.child,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  }) : getValue = null,
       listenable = null;

  const FractionallyBuilder.listenable({
    required Listenable this.listenable,
    required double Function() this.getValue,
    required this.builder,
    this.child,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  }) : value = null;

  const FractionallyBuilder.listenableBool({
    required ValueListenable<bool> value,
    required this.builder,
    this.child,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  }) : value = null,
       getValue = null,
       listenable = value;

  final double? value;
  final double Function()? getValue;
  final Listenable? listenable;
  final Widget? child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;

  @override
  State<FractionallyBuilder> createState() => _FractionallyBuilder();
}

class _FractionallyBuilder extends State<FractionallyBuilder>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    value:
        widget.value ??
        widget.getValue?.call() ??
        widget.listenable._value ??
        0,
  );

  late final _animation = _controller.drive(CurveTween(curve: widget.curve));

  @override
  void initState() {
    super.initState();
    widget.listenable?.addListener(_listener);
  }

  @override
  void dispose() {
    widget.listenable?.removeListener(_listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FractionallyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null) {
      if (widget.value == oldWidget.value) return;
      _controller.animateTo(widget.value!);
    }
  }

  void _listener() {
    final lis = widget.listenable;
    if (widget.getValue != null) {
      final newValue = widget.getValue!();
      _controller.animateTo(newValue);
    } else if (lis is ValueListenable<bool>) {
      final newValue = lis.value ? 1.0 : 0.0;
      _controller.animateTo(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) =>
          widget.builder(context, _animation.value, child),
    );
  }
}

extension on Listenable? {
  double? get _value => this is! ValueListenable<bool>
      ? null
      : ((this! as ValueListenable<bool>).value ? 1.0 : 0.0);
}
