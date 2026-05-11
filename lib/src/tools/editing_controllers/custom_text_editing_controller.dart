import 'package:flutter/widgets.dart';
import 'package:utils_well_dart/utils_well_dart.dart';

class CustomTextEditingController<T> extends TextEditingController {
  CustomTextEditingController({
    required this.toData,
    required this.fromData,
    T? initialValue,
  }) : super(text: initialValue?.let(fromData));

  final T Function(String) toData;
  final String Function(T) fromData;

  T? get data => text.let(toData);
  set data(T? value) => text = value?.let(fromData) ?? '';
}
