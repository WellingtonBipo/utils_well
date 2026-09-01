import 'package:flutter/widgets.dart';

extension EdgeInsetsExtension on EdgeInsets {
  double get _l => left;
  double get _t => top;
  double get _r => right;
  double get _b => bottom;

  EdgeInsets onlyHorizontal() => EdgeInsets.only(left: left, right: right);
  EdgeInsets onlyVertical() => EdgeInsets.only(top: top, bottom: bottom);
  EdgeInsets onlyTop() => EdgeInsets.only(top: top);
  EdgeInsets onlyBottom() => EdgeInsets.only(bottom: bottom);
  EdgeInsets onlyLeft() => EdgeInsets.only(left: left);
  EdgeInsets onlyRight() => EdgeInsets.only(right: right);

  EdgeInsets noTop() => EdgeInsets.only(left: _l, right: _r, bottom: _b);
  EdgeInsets noBottom() => EdgeInsets.only(left: _l, right: _r, top: _t);
  EdgeInsets noLeft() => EdgeInsets.only(top: _t, right: _r, bottom: _b);
  EdgeInsets noRight() => EdgeInsets.only(top: _t, left: _l, bottom: _b);

  EdgeInsets operator *(double factor) => EdgeInsets.only(
    left: _l * factor,
    top: _t * factor,
    right: _r * factor,
    bottom: _b * factor,
  );

  EdgeInsets only({
    bool top = false,
    bool bottom = false,
    bool left = false,
    bool right = false,
  }) => EdgeInsets.only(
    top: top ? this.top : 0,
    left: left ? this.left : 0,
    bottom: bottom ? this.bottom : 0,
    right: right ? this.right : 0,
  );
}
