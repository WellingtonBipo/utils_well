import 'package:flutter/material.dart';

extension TextStyleExtension on TextStyle {
  Size textWidgetSize(
    BuildContext context, {
    String text = '',
    double maxWidth = double.infinity,
    TextScaler? textScaler,
  }) {
    final textPainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
      text: TextSpan(text: text, style: this),
    )..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  List<LineMetrics> textWidgetLineMetrics(
    BuildContext context, {
    String text = '',
    double maxWidth = double.infinity,
    TextScaler? textScaler,
  }) {
    final textPainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
      text: TextSpan(text: text, style: this),
    )..layout(maxWidth: maxWidth);
    return textPainter.computeLineMetrics();
  }
}
