import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:utils_well/src/extensions/build_context_extension.dart';
import 'package:utils_well/src/extensions/text_style_extension.dart';
import 'package:utils_well/src/tools/add_post_frame_callback.dart';

final _snackBars = <String, List<({GlobalKey space, GlobalKey snack})>>{};

void showSnackBar({
  required BuildContext context,
  required String message,
  Duration? duration,
  double width = 300,
  double padding = 16,
  TextStyle? textStyle,
  Color? backgroundColor,
  BorderRadiusGeometry? borderRadius,
}) {
  final snackPadding = padding;
  final snackWidth = width;

  final dur = duration ?? Duration(milliseconds: message.length * 90);
  final show = ValueNotifier(false);
  final spaceKey = GlobalKey();
  final snackKey = GlobalKey();

  final bottomPadding = max(20, MediaQuery.viewInsetsOf(context).bottom);

  var totalSnacksHeight = 0.0;

  final infos = _snackBars[message]._infos();
  if (infos != null) {
    totalSnacksHeight = infos.top - infos.height - bottomPadding;
  } else if (_snackBars.keys.isNotEmpty) {
    final h = _snackBars.keys.fold<double>(0, (s, e) {
      return max(s, _snackBars[e]._infos()!.top - bottomPadding + 10);
    });
    totalSnacksHeight = h;
  }

  final keys = (space: spaceKey, snack: snackKey);
  _snackBars.putIfAbsent(message, () => []).add(keys);

  addPostFrameCallback(() => show.value = true);

  final style =
      textStyle ??
      context.theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600) ??
      TextStyle(
        fontWeight: .w600,
        color: context.theme.appBarTheme.foregroundColor,
      );

  final textHeight = style.textWidgetSize(
    context,
    text: message,
    maxWidth: snackWidth - (2 * snackPadding),
  );

  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (context) => Align(
      alignment: .bottomCenter,
      child: Container(
        key: spaceKey,
        padding: .only(bottom: bottomPadding + totalSnacksHeight),
        child: AnimatedBuilder(
          animation: show,
          builder: (context, _) {
            Future<void> dismiss(bool wait) async {
              if (wait) await Future.delayed(dur);
              if (!show.value) return;
              if (_snackBars[message]?.length == 1) {
                show.value = false;
                await Future.delayed(const Duration(milliseconds: 300));
              }
              _snackBars[message]?.remove(keys);
              if (_snackBars[message]?.isEmpty ?? false) {
                _snackBars.remove(message);
              }
              show.dispose();
              entry?.remove();
            }

            final yOffset = show.value
                ? 0.0
                : textHeight.height + 2 * snackPadding + totalSnacksHeight;

            return AnimatedContainer(
              onEnd: () => dismiss(true),
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(0, yOffset, 0),
              child: GestureDetector(
                onTap: () => dismiss(false),
                child: Container(
                  key: snackKey,
                  padding: .all(snackPadding),
                  width: snackWidth,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                  ),
                  child: Text(message, style: style),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
}

extension on List<({GlobalKey space, GlobalKey snack})>? {
  ({double top, double height})? _infos() {
    final space = this?.firstOrNull?.space.currentContext;
    final snack = this?.firstOrNull?.snack.currentContext;
    final spaceRect = space?.findRenderObjectLocalToGlobalRect(.zero);
    final snackRect = snack?.findRenderObjectLocalToGlobalRect(.zero);
    if (spaceRect == null || snackRect == null) return null;
    return (
      height: snackRect.height,
      top: spaceRect.height,
    );
  }
}
