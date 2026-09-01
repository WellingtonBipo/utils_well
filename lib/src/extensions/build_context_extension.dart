import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  double scale(double i) => MediaQuery.textScalerOf(this).scale(i);

  Rect? findRenderObjectLocalToGlobalRect(
    Offset point, {
    RenderObject? ancestor,
  }) {
    final renderBox = findRenderObject();
    if (renderBox is! RenderBox) return null;
    return renderBox.localToGlobal(point, ancestor: ancestor) & renderBox.size;
  }

  double bottomPaddingWithDevice({
    required double minPadding,
    double whenHasDevicePadding = 0,
  }) {
    final bottomDevice = MediaQuery.of(this).padding.bottom;
    var bottom = bottomDevice + whenHasDevicePadding;
    if (bottom < minPadding) bottom = minPadding;
    return bottom;
  }
}
