import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumEditingController<T extends num> extends TextEditingController {
  NumEditingController({T? number, NumInputFormatter<T>? formatter}) {
    _formatter = formatter ?? NumInputFormatter<T>();
    _formatter._controller = this;
    _number = (number, false);
    super.value = _formatter._editingValue(_formatter.toText(number));
    _canNotify = true;
  }

  late NumInputFormatter<T> _formatter;
  NumInputFormatter<T> get formatter => _formatter;

  bool _canNotify = false;

  var _oldValue = TextEditingValue.empty;
  late (T?, bool settedByFormatter) _number;

  T? get number => _number.$1;
  set number(T? value) {
    final text = _formatter.toText(value);
    if (text.length > (_formatter.lengthLimiting ?? double.infinity)) return;
    _number = (value, false);
    super.value = _formatter._editingValue(text);
  }

  @override
  set value(TextEditingValue newValue) {
    final text = newValue.text;
    var finalValue = newValue;
    if (text != value.text && !_number.$2) {
      finalValue = _formatter.formatEditUpdate(_oldValue, newValue);
    }
    _number = (_number.$1, false);
    super.value = finalValue;
    _oldValue = super.value;
  }

  @override
  void notifyListeners() {
    if (_canNotify) super.notifyListeners();
  }
}

final class NumInputFormatter<T extends num> extends TextInputFormatter {
  NumInputFormatter({
    this.hundredSeparator = '',
    int decimalPoint = 0,
    this.decimalSeparator = '.',
    this.signType = NumInputFormatterSignType.none,
    this.canBeEmpty = true,
    this.canBeZero = true,
    this.lengthLimiting,
  }) : decimalPoint = decimalPoint < 0 ? 0 : decimalPoint;

  final String hundredSeparator;
  final int decimalPoint;
  final String decimalSeparator;
  final NumInputFormatterSignType signType;
  final bool canBeEmpty;
  final bool canBeZero;
  final int? lengthLimiting;

  NumEditingController<T>? _controller;

  String sign(T? value) => signType._sign(value?.toString() ?? '');

  String toText(T? value) {
    if (value == null && canBeEmpty) return '';
    final v = value ?? (canBeZero ? 0 : (1 / pow(10, decimalPoint))) as T;
    final valueSplit = v.toStringAsFixed(decimalPoint).split('.');
    var valueString = valueSplit.first;
    if (valueString.startsWith('-') || valueString.startsWith('+')) {
      valueString = valueString.substring(1);
    }
    final values = <String>[];
    if (hundredSeparator.isNotEmpty) {
      for (var i = valueString.length; i > 0; i -= 3) {
        final startIdx = i - 3 < 0 ? 0 : i - 3;
        values.add(valueString.substring(startIdx, i));
      }
      valueString = values.reversed.join(hundredSeparator);
    }
    if (valueSplit.length == 1) return '${sign(v)}$valueString';
    return '${sign(v)}$valueString$decimalSeparator${valueSplit.last}';
  }

  T? fromText(String text) => _fromText(text).$1;

  (T?, bool useOldValue) _fromText(String t) {
    final text = t.trim();
    if (text.length > (lengthLimiting ?? double.infinity)) return (null, true);
    if (text.isEmpty && canBeEmpty) return (null, false);
    if (text == '-' || text == '+') return (null, false);
    if (text == decimalSeparator) return (null, false);
    if (text == hundredSeparator) return (null, false);
    final regex = RegExp('[^0-9$decimalSeparator$hundredSeparator+-]');
    if (text.contains(regex)) return (null, true);
    final v = '${signType._sign(text)}${_formattedToNumString(text)}';
    final value = (T == int ? int.tryParse(v) : double.tryParse(v)) as T?;
    if (value != 0) return (value, false);
    if (!canBeZero && !canBeEmpty) return (null, true);
    if (!canBeEmpty) return (value, false);
    if (!canBeZero) return (null, false);
    return (value, false);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final (value, useOldValue) = _fromText(newValue.text);
    if (useOldValue) return _editingValue(oldValue.text);
    final lastNumber = _controller != null
        ? _controller!._number.$1
        : (num.parse(_formattedToNumString(oldValue.text)) as T);
    var text = toText(value);
    bool isDeleting() => oldValue.text.startsWith(RegExp(newValue.text));
    if (canBeEmpty && lastNumber == 0 && isDeleting()) text = '';
    _controller?._number = (text.isEmpty ? null : value, true);
    return _editingValue(text);
  }

  String _formattedToNumString(String text) {
    var t = text;
    t = t.replaceAll(RegExp('[^0-9]'), '').padLeft(decimalPoint + 1, '0');
    if (decimalPoint > 0) {
      final decimalIndex = t.length - decimalPoint;
      t = '${t.substring(0, decimalIndex)}.${t.substring(decimalIndex)}';
    }
    return t;
  }

  TextEditingValue _editingValue(String text) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
}

enum NumInputFormatterSignType {
  none,
  positiveOrNegative,
  alwaysPositive,
  alwaysNegative,
  showNegative;

  String _sign(String text) {
    switch (this) {
      case NumInputFormatterSignType.none:
        return '';
      case NumInputFormatterSignType.alwaysPositive:
        return '+';
      case NumInputFormatterSignType.alwaysNegative:
        return '-';
      case NumInputFormatterSignType.showNegative:
      case NumInputFormatterSignType.positiveOrNegative:
        var t = text;
        final startsNeg = text.startsWith('-');
        if (startsNeg) t = text.replaceFirst('-', '');
        final containsNeg = t.contains('-');
        if (this == NumInputFormatterSignType.showNegative) {
          if (startsNeg || containsNeg) return '-';
          return '';
        }
        final startsPos = text.startsWith('+');
        if (startsPos) t = text.replaceFirst('+', '');
        final containsPos = t.contains('+');
        if (startsPos) return containsNeg ? '+' : '-';
        if (startsNeg) return containsPos ? '+' : '-';
        if (containsNeg) return '-';
        if (containsPos) return '+';
        return '';
    }
  }
}
