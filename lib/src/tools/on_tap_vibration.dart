import 'package:flutter/services.dart';

sealed class OnTapVibration {
  static void Function()? onTap(
    void Function()? onTapCallback, {
    bool tapEnabled = true,
  }) {
    if (onTapCallback == null || !tapEnabled) return null;
    return () {
      HapticFeedback.lightImpact();
      onTapCallback();
    };
  }
}
