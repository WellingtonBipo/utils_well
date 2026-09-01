import 'package:flutter/widgets.dart';
import 'package:utils_well/src/extensions/build_context_extension.dart';

extension NumExtension on num {
  Widget get spaceH => SizedBox(height: toDouble());
  Widget get spaceW => SizedBox(width: toDouble());
  double scale(BuildContext context) => context.scale(toDouble());
}
