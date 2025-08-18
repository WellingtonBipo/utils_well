import 'package:flutter/material.dart';

class SliverContainer extends SliverToBoxAdapter {
  const SliverContainer({
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.decoration,
    Widget? child,
    super.key,
  })  : _child = child,
        super();

  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Decoration? decoration;
  final Widget? _child;

  @override
  Widget get child => Container(
        margin: margin,
        padding: padding,
        height: height,
        width: width,
        decoration: decoration,
        child: _child,
      );
}
