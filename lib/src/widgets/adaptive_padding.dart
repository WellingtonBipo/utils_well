import 'dart:math' as m;

import 'package:flutter/material.dart';

// ignore_for_file: comment_references

class AdaptivePadding {
  const AdaptivePadding({
    required EdgeInsets padding,
    required this.bottomPaddingWhenHasDevicePadding,
    required this.paddingType,
  }) : _innerPadding = padding;

  static const zero = AdaptivePadding(
    padding: EdgeInsets.zero,
    paddingType: .onlyInnerPadding,
    bottomPaddingWhenHasDevicePadding: 0,
  );

  final EdgeInsets _innerPadding;

  final AdaptivePaddingPaddingType paddingType;

  /// Bottom padding that will use when
  /// ([MediaQuery.padding.bottom] +
  /// [bottomPaddingWhenHasDevicePadding]) > padding.bottom.
  ///
  /// Examples:
  ///
  /// padding.bottom = 16<br>
  /// [bottomPaddingWhenHasDevicePadding] = 8<br>
  /// [MediaQuery.padding.bottom] = 5<br>
  /// Result = 16
  ///
  /// padding.bottom = 16<br>
  /// [bottomPaddingWhenHasDevicePadding] = 8<br>
  /// [MediaQuery.padding.bottom] = 10<br>
  /// Result = 18
  ///
  /// padding.bottom = 0<br>
  /// [bottomPaddingWhenHasDevicePadding] = 8<br>
  /// [MediaQuery.padding.bottom] = 10<br>
  /// Result = 18
  ///
  final double bottomPaddingWhenHasDevicePadding;

  AdaptivePaddingEdgeInsets toPadding(
    BuildContext context, {
    double? left,
    double? right,
    double? top,
    double? bottom,
    AdaptivePaddingPaddingType? paddingType,
  }) {
    final padType = paddingType ?? this.paddingType;
    // Early return to not mark context to rebuild.
    if (bottom != null ||
        padType == AdaptivePaddingPaddingType.onlyInnerPadding) {
      return AdaptivePaddingEdgeInsets(
        top: top ?? _innerPadding.top,
        left: left ?? _innerPadding.left,
        right: right ?? _innerPadding.right,
        innerBottomPadding: bottom ?? _innerPadding.bottom,
      );
    }

    var paddingWhenHasDevicePadding = bottomPaddingWhenHasDevicePadding;
    if (paddingWhenHasDevicePadding > _innerPadding.bottom) {
      paddingWhenHasDevicePadding = _innerPadding.bottom;
    }

    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    var extraPad = viewPadding;
    var spaceAboveViewPadding = 0.0;

    switch (padType) {
      case AdaptivePaddingPaddingType.onlyInnerPadding:
      case AdaptivePaddingPaddingType.viewPadding:
        break;
      case AdaptivePaddingPaddingType.viewInsets:
        extraPad = m.max(viewPadding, MediaQuery.viewInsetsOf(context).bottom);
        spaceAboveViewPadding = extraPad - viewPadding;
        final remainingInnerPadding =
            _innerPadding.bottom - paddingWhenHasDevicePadding;
        if (spaceAboveViewPadding > remainingInnerPadding) {
          spaceAboveViewPadding = remainingInnerPadding;
        }
        break;
    }

    var innerPad = _innerPadding.bottom;
    final consumed = extraPad - innerPad;
    if (consumed > 0) {
      innerPad = (_innerPadding.bottom - consumed).clamp(
        paddingWhenHasDevicePadding,
        _innerPadding.bottom,
      );
      innerPad += spaceAboveViewPadding;
    }

    return AdaptivePaddingEdgeInsets(
      left: left ?? _innerPadding.left,
      right: right ?? _innerPadding.right,
      top: top ?? _innerPadding.top,
      innerBottomPadding: innerPad,
      extraBottomPadding: extraPad,
    );
  }

  AdaptivePadding copyWith({
    double? top,
    double? bottom,
    double? left,
    double? right,
    EdgeInsets? padding,
    AdaptivePaddingPaddingType? paddingType,
    double? bottomPaddingWhenHasDevicePadding,
  }) {
    return AdaptivePadding(
      bottomPaddingWhenHasDevicePadding:
          bottomPaddingWhenHasDevicePadding ??
          this.bottomPaddingWhenHasDevicePadding,
      paddingType: paddingType ?? this.paddingType,
      padding:
          padding ??
          _innerPadding.copyWith(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
          ),
    );
  }

  AdaptivePadding removeBottom({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return copyWith(
      left: left,
      top: top,
      right: right,
      bottom: bottom ?? 0,
      bottomPaddingWhenHasDevicePadding: 0,
      paddingType: AdaptivePaddingPaddingType.onlyInnerPadding,
    );
  }

  AdaptivePadding onlyHorizontal({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return copyWith(
      left: left,
      right: right,
      top: top ?? 0,
      bottom: bottom ?? 0,
      bottomPaddingWhenHasDevicePadding: 0,
      paddingType: AdaptivePaddingPaddingType.onlyInnerPadding,
    );
  }

  AdaptivePadding onlyVertical({
    double? left,
    double? right,
    double? top,
    double? bottom,
    AdaptivePaddingPaddingType? paddingType,
    double? bottomPaddingWhenHasDevicePadding,
  }) {
    return copyWith(
      left: left ?? 0,
      right: right ?? 0,
      top: top,
      bottom: bottom,
      paddingType: paddingType,
      bottomPaddingWhenHasDevicePadding: bottomPaddingWhenHasDevicePadding,
    );
  }

  AdaptivePadding onlyTop({
    double? left,
    double? right,
    double? top,
    double? bottom,
    AdaptivePaddingPaddingType? paddingType,
    double? bottomPaddingWhenHasDevicePadding,
  }) => onlyVertical(
    top: top,
    left: left,
    right: right,
    bottom: bottom ?? 0,
    paddingType: paddingType ?? .onlyInnerPadding,
    bottomPaddingWhenHasDevicePadding: bottomPaddingWhenHasDevicePadding ?? 0,
  );

  AdaptivePadding onlyBottom({
    double? left,
    double? right,
    double? top,
    double? bottom,
    AdaptivePaddingPaddingType? paddingType,
    double? bottomPaddingWhenHasDevicePadding,
  }) => onlyVertical(
    top: top ?? 0,
    left: left,
    right: right,
    bottom: bottom,
    paddingType: paddingType,
    bottomPaddingWhenHasDevicePadding: bottomPaddingWhenHasDevicePadding,
  );

  @override
  String toString() =>
      '''
DSScaffoldBodyPadding
  _innerPadding: $_innerPadding,
  paddingType: $paddingType,
  bottomPaddingWhenHasDevicePadding: $bottomPaddingWhenHasDevicePadding''';
}

class AdaptivePaddingEdgeInsets extends EdgeInsets {
  const AdaptivePaddingEdgeInsets({
    super.top = 0,
    super.left = 0,
    super.right = 0,
    this.innerBottomPadding = 0,
    this.extraBottomPadding = 0,
  }) : super.only();

  final double innerBottomPadding;
  final double extraBottomPadding;

  @override
  double get bottom => innerBottomPadding + extraBottomPadding;

  @override
  AdaptivePaddingEdgeInsets copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? innerBottomPadding,
    double? extraBottomPadding,
  }) {
    var inner = innerBottomPadding ?? this.innerBottomPadding;
    var extra = extraBottomPadding ?? this.extraBottomPadding;
    if (bottom != null) {
      inner = bottom;
      extra = 0;
    }
    return AdaptivePaddingEdgeInsets(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      innerBottomPadding: inner,
      extraBottomPadding: extra,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptivePaddingEdgeInsets &&
        other.innerBottomPadding == innerBottomPadding &&
        other.extraBottomPadding == extraBottomPadding &&
        other.top == top &&
        other.left == left &&
        other.right == right;
  }

  @override
  int get hashCode =>
      innerBottomPadding.hashCode ^
      extraBottomPadding.hashCode ^
      super.hashCode;
}

enum AdaptivePaddingPaddingType {
  onlyInnerPadding,

  /// Will use the standard [MediaQueryData.viewPadding], even when the
  /// [MediaQueryData.viewInsets] is bigger than padding.
  viewPadding,

  /// Will use the biggest between [MediaQueryData.viewInsets] and
  /// [MediaQueryData.viewPadding].
  /// Ex: When keyboard is open, will give the keyboard height plus the
  /// provided padding.
  viewInsets,
}

class AdaptivePaddingWidget extends StatelessWidget {
  const AdaptivePaddingWidget({
    required this.padding,
    this.child,
    this.builder,
    this.usePaddingWhenNoChild = true,
    this.safeArea = const AdaptivePaddingSafeArea(),
    this.removeMediaQueryPadding = false,
    super.key,
  });

  final AdaptivePadding padding;
  final Widget? child;
  final Widget? Function(BuildContext context)? builder;
  final AdaptivePaddingSafeArea safeArea;
  final bool usePaddingWhenNoChild;
  final bool removeMediaQueryPadding;

  @override
  Widget build(BuildContext context) {
    final adaptPad = padding.toPadding(context);
    final mqPad = MediaQuery.paddingOf(context);
    return MediaQuery.removePadding(
      context: context,
      removeLeft: removeMediaQueryPadding,
      removeTop: removeMediaQueryPadding,
      removeRight: removeMediaQueryPadding,
      removeBottom: removeMediaQueryPadding,
      child: _Child(adaptPad, mqPad),
    );
  }
}

class _Child extends StatelessWidget {
  const _Child(this.adaptivePadding, this.mqPadding);

  final EdgeInsets adaptivePadding;
  final EdgeInsets mqPadding;

  @override
  Widget build(BuildContext context) {
    final parent = context
        .findAncestorWidgetOfExactType<AdaptivePaddingWidget>()!;

    final child = parent.child ?? parent.builder?.call(context);

    double v(double mq, double adapt, bool useSafeArea) {
      double max() => m.max(useSafeArea ? mq : 0.0, adapt);
      if (child != null) return max();
      return parent.usePaddingWhenNoChild ? max() : 0;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: parent.safeArea.bottom ? adaptivePadding.bottom : 0,
        top: v(mqPadding.top, adaptivePadding.top, parent.safeArea.top),
        left: v(mqPadding.left, adaptivePadding.left, parent.safeArea.left),
        right: v(mqPadding.right, adaptivePadding.right, parent.safeArea.right),
      ),
      child: child,
    );
  }
}

class AdaptivePaddingSafeArea {
  const AdaptivePaddingSafeArea({
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
}

extension AdaptiveEdgeInsetsExtension on EdgeInsets {
  EdgeInsets onlyHorizontal() => EdgeInsets.only(left: left, right: right);
  EdgeInsets onlyVertical() => EdgeInsets.only(top: top, bottom: bottom);
  EdgeInsets onlyTop() => EdgeInsets.only(top: top);
  EdgeInsets onlyBottom() => EdgeInsets.only(bottom: bottom);
  EdgeInsets onlyLeft() => EdgeInsets.only(left: left);
  EdgeInsets onlyRight() => EdgeInsets.only(right: right);
}
