import 'package:flutter/material.dart';
import 'package:utils_well/src/extensions/build_context_extension.dart';
import 'package:utils_well/utils_well_dart/lib/utils_well_dart.dart';

extension ScrollControllerExtension on ScrollController {
  Future<void> animateToWidget(
    BuildContext widgetContext, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!hasClients) throw Exception('ScrollController has no clients');

    final scrollable = widgetContext.findAncestorStateOfType<ScrollableState>();
    if (scrollable == null) throw Exception('Scrollable not found');

    final widgetRect = widgetContext.findRenderObjectLocalToGlobalRect(
      Offset.zero,
      ancestor: scrollable.context.findRenderObject(),
    );
    if (widgetRect == null) throw Exception('Item not found');

    final widgetPositionInsideScroll = position.pixels + widgetRect.left;
    final widgetCenterPositionInsideScroll =
        widgetPositionInsideScroll + (widgetRect.width / 2);
    var scrollPosition =
        widgetCenterPositionInsideScroll - (position.extentInside / 2);

    final maxScrollExtent = position.maxScrollExtent;
    if (scrollPosition < 0) scrollPosition = 0;
    if (scrollPosition > maxScrollExtent) scrollPosition = maxScrollExtent;

    return animateTo(scrollPosition, duration: duration, curve: curve);
  }

  Future<void> animateWidgetToStart(
    BuildContext widgetContext, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double minStartOffsetRatio = 0,
    double? minEndOffsetRatio,
  }) async {
    if (!hasClients) throw Exception('ScrollController has no clients');

    final scrollable = widgetContext.findAncestorStateOfType<ScrollableState>();
    if (scrollable == null) throw Exception('Scrollable not found');

    final widgetRect = widgetContext.findRenderObjectLocalToGlobalRect(
      Offset.zero,
      ancestor: scrollable.context.findRenderObject(),
    );
    if (widgetRect == null) throw Exception('Item not found');

    final minStartOffset = position.viewportDimension * minStartOffsetRatio;
    final minEndOffset =
        position.viewportDimension * (minEndOffsetRatio ?? minStartOffsetRatio);
    var scrollPosition = position.pixels;
    switch (scrollable.axisDirection) {
      case AxisDirection.up:
        break;
      case AxisDirection.down:
        if (widgetRect.top.isBetween(minStartOffset, minEndOffset)) break;
        if (widgetRect.top < minStartOffset) {
          scrollPosition = scrollPosition + widgetRect.top - minStartOffset;
        } else {
          scrollPosition = scrollPosition + widgetRect.top - minEndOffset;
        }
        if (scrollPosition <= position.maxScrollExtent) break;
        scrollPosition = position.maxScrollExtent;
        break;
      case AxisDirection.left:
        break;
      case AxisDirection.right:
        break;
    }

    return animateTo(scrollPosition, duration: duration, curve: curve);
  }
}
