import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumEditingController<T extends num?> extends TextEditingController {
  NumEditingController({T? num, NumInputFormatter<T>? formatter}) {
    _formatter = formatter ?? NumInputFormatter<T>();
    text = _formatter.toText(num);
  }

  late NumInputFormatter<T> _formatter;
  NumInputFormatter<T> get formatter => _formatter;

  T get num => _formatter.fromText(text) ?? 0 as T;
  set num(T value) => text = _formatter.toText(value);

  @override
  set text(String newText) {
    final num = _formatter.fromText(newText);
    if (num == null) return;
    super.text = newText;
  }
}

final class NumInputFormatter<T extends num?> extends TextInputFormatter {
  const NumInputFormatter({
    this.hundredSeparator = '',
    int decimalPoint = 0,
    this.decimalSeparator = '.',
    this.signType = NumInputFormatterSignType.none,
    this.canBeEmpty = true,
    this.canBeZero = true,
  }) : decimalPoint = decimalPoint < 0 ? 0 : decimalPoint;

  final String hundredSeparator;
  final int decimalPoint;
  final String decimalSeparator;
  final NumInputFormatterSignType signType;
  final bool canBeEmpty;
  final bool canBeZero;

  String sign(T? value) => signType._sign(value?.toString() ?? '');

  String toText(T? value) {
    if (value == null && canBeEmpty) return '';
    final v = value ?? (canBeZero ? 0 : (1 / pow(10, decimalPoint))) as T;
    final valueSplit = v!.toStringAsFixed(decimalPoint).split('.');
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

  T? fromText(String text) {
    var v = text;
    if (hundredSeparator.isNotEmpty) v = v.replaceAll(hundredSeparator, '');
    v = v.replaceAll(decimalSeparator, '.');
    if (T == int) return int.tryParse(v) as T?;
    if (T == double) return double.tryParse(v) as T?;
    return num.tryParse(v) as T?;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.trim();
    if (text.isEmpty && canBeEmpty) return _editingValue('');
    if (text == '-' || text == '+') return _editingValue('');
    if (text == decimalSeparator) return _editingValue('');
    if (text == hundredSeparator) return _editingValue('');
    if (text.contains(RegExp('[^0-9$decimalSeparator$hundredSeparator+-]'))) {
      return _editingValue(oldValue.text);
    }
    final sign = signType._sign(text);
    final value = num.parse('$sign${_valueText(text)}') as T;
    if (value == 0) {
      if (!canBeZero && !canBeEmpty) return _editingValue(oldValue.text);
      if (canBeEmpty) {
        if (!canBeZero) return _editingValue('');
        bool isDeleting() => oldValue.text.startsWith(RegExp('$text.'));
        bool lastIsZero() => num.parse(_valueText(oldValue.text)) == 0;
        if (isDeleting() && lastIsZero()) return _editingValue('');
      }
    }
    return _editingValue(toText(value));
  }

  String _valueText(String text) {
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
