import 'package:flutter/widgets.dart';
import 'package:utils_well_dart/utils_well_dart.dart';

class CustomTextEditingController<T> extends TextEditingController {
  CustomTextEditingController({
    required this.toData,
    required this.fromData,
    required T initialData,
  }) : super(text: fromData(initialData));

  final T Function(String text) toData;
  final String Function(T data) fromData;

  T get data => text.let(toData);
  set data(T value) => text = fromData(value);
}
