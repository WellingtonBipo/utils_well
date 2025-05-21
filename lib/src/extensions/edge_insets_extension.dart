import 'package:flutter/material.dart';

extension EdgeInsetsExtension on EdgeInsets {
  EdgeInsets onlyHorizontal() => EdgeInsets.only(left: left, right: right);
  EdgeInsets onlyVertical() => EdgeInsets.only(top: top, bottom: bottom);
  EdgeInsets onlyTop() => EdgeInsets.only(top: top);
  EdgeInsets onlyBottom() => EdgeInsets.only(bottom: bottom);
  EdgeInsets onlyLeft() => EdgeInsets.only(left: left);
  EdgeInsets onlyRight() => EdgeInsets.only(right: right);
}
