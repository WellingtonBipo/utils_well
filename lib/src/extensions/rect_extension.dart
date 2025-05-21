import 'package:flutter/widgets.dart';

extension RectExtension on Rect {
  Rect addPadding(EdgeInsets? padding) {
    if (padding == null) return this;
    return Rect.fromLTRB(
      left - padding.left,
      top - padding.top,
      right + padding.right,
      bottom + padding.bottom,
    );
  }
}
