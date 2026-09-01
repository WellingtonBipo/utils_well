import 'package:flutter/material.dart';
import 'package:utils_well/utils_well.dart';

extension ColorExt on Color {
  String toJson() => 'a:$a,r:$r,g:$g,b:$b';

  static Color? fromJson(String? data) {
    final c = data?.trim();
    if (c == null || c.isEmpty) return null;
    final parts = c.split(',');
    if (parts.length != 4) return null;
    final [a, r, g, b] = parts.mapToList(
      (e, _) => double.parse(e.split(':')[1]),
    );
    return Color.from(alpha: a, red: r, green: g, blue: b);
  }
}
