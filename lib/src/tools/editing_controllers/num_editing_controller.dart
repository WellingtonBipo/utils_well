import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utils_well_dart/utils_well_dart.dart';

class NumEditingController extends TextEditingController {
  NumEditingController({double? number, NumInputFormatter? formatter}) {
    _formatter = formatter ?? NumInputFormatter();
    assert(
      _formatter._controller == null,
      'Each NumEditingController must have its own'
      ' instance of NumInputFormatter',
    );
    _formatter._controller = this;
    _number = (number, false);
    super.value = _formatter._editingValue(_formatter._toText(number));
    _oldValue = super.value;
    _canNotify = true;
  }

  late NumInputFormatter _formatter;
  NumInputFormatter get formatter => _formatter;

  bool _canNotify = false;

  var _oldValue = TextEditingValue.empty;
  late (double?, bool settedByFormatter) _number;

  double? get number => _number.$1;
  set number(num? value) {
    final v = value?.toDouble();
    final text = _formatter._toText(v);
    if (_formatter.textHigherThanLength(text)) return;
    _number = (v, false);
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

final class NumInputFormatter extends TextInputFormatter {
  NumInputFormatter({
    this.thousandSeparator = '',
    int decimalPoint = 0,
    this.alwaysShowDecimalPoint = true,
    this.decimalSeparator = '.',
    this.signType = NumInputFormatterSignType.none,
    this.canBeEmpty = true,
    this.canBeZero = true,
    this.lengthLimiting,
    this.leadingText,
  }) : decimalPoint = decimalPoint < 0 ? 0 : decimalPoint;

  final String thousandSeparator;
  final int decimalPoint;
  final bool alwaysShowDecimalPoint;
  final String decimalSeparator;
  final NumInputFormatterSignType signType;
  final bool canBeEmpty;
  final bool canBeZero;
  final int? lengthLimiting;
  final String? leadingText;

  NumInputFormatter copyWith({
    String? thousandSeparator,
    int? decimalPoint,
    bool? alwaysShowDecimalPoint,
    String? decimalSeparator,
    NumInputFormatterSignType? signType,
    bool? canBeEmpty,
    bool? canBeZero,
    int? lengthLimiting,
    String? leadingText,
  }) => NumInputFormatter(
    thousandSeparator: thousandSeparator ?? this.thousandSeparator,
    decimalPoint: decimalPoint ?? this.decimalPoint,
    alwaysShowDecimalPoint:
        alwaysShowDecimalPoint ?? this.alwaysShowDecimalPoint,
    decimalSeparator: decimalSeparator ?? this.decimalSeparator,
    signType: signType ?? this.signType,
    canBeEmpty: canBeEmpty ?? this.canBeEmpty,
    canBeZero: canBeZero ?? this.canBeZero,
    lengthLimiting: lengthLimiting ?? this.lengthLimiting,
    leadingText: leadingText ?? this.leadingText,
  );

  NumEditingController? _controller;

  String sign(double? value) => value == null || value == 0 || value == 0.0
      ? ''
      : signType._sign(value.toString()).$2;

  String toText(double? value) => _toText(value);

  String _toText([double? value, bool? isPositive, String? newText]) {
    if (value == null && canBeEmpty) return '';
    if (value == 0 && canBeEmpty && !canBeZero) return '';
    final v = value ?? (canBeZero ? 0 : (1 / pow(10, decimalPoint)));
    final valueSplit = v.toStringAsFixed(decimalPoint).split('.');
    var valueString = valueSplit.first;
    var s = '';
    if (valueString.startsWith('-') || valueString.startsWith('+')) {
      s = valueString.substring(0, 1);
      valueString = valueString.substring(1);
    }
    final values = <String>[];
    if (thousandSeparator.isNotEmpty) {
      for (var i = valueString.length; i > 0; i -= 3) {
        final startIdx = i - 3 < 0 ? 0 : i - 3;
        values.add(valueString.substring(startIdx, i));
      }
      valueString = values.reversed.join(thousandSeparator);
    }
    if (isPositive != null) s = isPositive ? '+' : '-';
    valueString = '${leadingText ?? ''}$s$valueString';
    if (!alwaysShowDecimalPoint) {
      if (valueSplit.length == 1) return '$s$valueString';
      var end = '', sep = '', newEnd = '';
      if (newText?.contains(decimalSeparator) ?? false) {
        sep = decimalSeparator;
        newEnd = newText!.split(decimalSeparator).last;
      }
      for (var i = valueSplit.last.length - 1; i >= 0; i--) {
        final char = valueSplit.last[i];
        if (char == '0' && end.isEmpty && newEnd.characterAt(i) != '0') {
          continue;
        }
        end = char + end;
      }
      if (end.isNotEmpty) sep = decimalSeparator;
      return '$valueString$sep$end';
    }
    if (valueSplit.length == 1) return valueString;
    return '$valueString$decimalSeparator${valueSplit.last}';
  }

  double? fromText(String text) => _fromText(text).$1;

  (double?, bool useOldValue, bool? isPositive) _fromText(String t) {
    var text = t.trim();
    if (text.isEmpty && canBeEmpty) return (null, false, null);
    if (text == '-' || text == '+') return (null, false, null);
    if (text == decimalSeparator) return (null, false, null);
    if (text == thousandSeparator) return (null, false, null);
    if (text == leadingText) return (null, false, null);
    if (leadingText != null && text.startsWith(leadingText!)) {
      text = text.substring(leadingText!.length);
    }
    final regex = RegExp('[^0-9$decimalSeparator$thousandSeparator+-]');
    if (text.contains(regex)) return (null, true, null);
    final valueString = _formattedToNumString(text);
    if (textHigherThanLength(valueString)) return (null, true, null);
    final isPositive = signType._sign(text).$1;
    final value = double.tryParse(valueString);
    if (value != 0) return (value, false, isPositive);
    if (!canBeZero && !canBeEmpty) return (null, true, isPositive);
    if (!canBeEmpty) return (value, false, isPositive);
    if (!canBeZero) return (null, false, isPositive);
    return (value, false, isPositive);
  }

  bool textHigherThanLength(String text) {
    if (lengthLimiting == null) return false;
    return text.replaceAll(RegExp('[^0-9]'), '').length > lengthLimiting!;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == newValue.text) return newValue;
    final (value, useOldValue, isPositive) = _fromText(newValue.text);
    if (useOldValue) return _editingValue(oldValue.text);
    final lastNumber = _controller != null
        ? _controller!._number.$1
        : double.parse(_formattedToNumString(oldValue.text));
    var text = _toText(value, isPositive, newValue.text);
    bool isDeleting() => oldValue.text.startsWith(RegExp(newValue.text));
    if (canBeEmpty && lastNumber == 0 && isDeleting()) text = '';
    var n = text.isEmpty ? null : value;
    if (n != null && isPositive == false) n = n * -1;
    _controller?._number = (n, true);
    return _editingValue(text);
  }

  String _formattedToNumString(String text) {
    var t = text.replaceAll(RegExp('[^0-9]'), '');

    if (alwaysShowDecimalPoint) {
      if (decimalPoint > 0) {
        t = t.padLeft(decimalPoint + 1, '0');
        final decimalIndex = t.length - decimalPoint;
        t = '${t.substring(0, decimalIndex)}.${t.substring(decimalIndex)}';
      }
    } else {
      if (text.contains(decimalSeparator)) {
        final tClean = text.replaceAll(RegExp('[^0-9$decimalSeparator]'), '');
        final sepIndex = tClean.indexOf(decimalSeparator);
        if (t.length - 1 <= sepIndex) t = t.padRight(sepIndex + 1, '0');
        t = '${t.substring(0, sepIndex)}.${t.substring(sepIndex)}';
      }
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
  showNegative
  ;

  (bool? isPositive, String sign) _sign(String text) {
    const empty = (null, ''), neg = (false, '-'), pos = (true, '+');
    switch (this) {
      case NumInputFormatterSignType.none:
        return empty;
      case NumInputFormatterSignType.alwaysPositive:
        return pos;
      case NumInputFormatterSignType.alwaysNegative:
        return neg;
      case NumInputFormatterSignType.showNegative:
      case NumInputFormatterSignType.positiveOrNegative:
        var t = text;
        final startsNeg = text.startsWith('-');
        if (startsNeg) t = text.replaceFirst('-', '');
        final containsNeg = t.contains('-');
        final startsPos = text.startsWith('+');
        if (startsPos) t = text.replaceFirst('+', '');
        final containsPos = t.contains('+');
        final posSign = this == NumInputFormatterSignType.showNegative
            ? empty
            : pos;
        if (startsPos) return containsNeg ? posSign : neg;
        if (startsNeg) return containsPos ? posSign : neg;
        if (containsNeg) return neg;
        if (containsPos) return posSign;
        return empty;
    }
  }
}
