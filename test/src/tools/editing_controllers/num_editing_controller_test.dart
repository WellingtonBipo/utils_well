// ignore_for_file: unnecessary_lambdas

import 'package:flutter_test/flutter_test.dart';
import 'package:utils_well/utils_well.dart';

var _formatter = () => NumInputFormatter();

late NumEditingController _controller;

String get _text => _controller.text;
set _text(String value) => _controller.text = value;

num? get _number => _controller.number;

void main() {
  void setValue(num v) {
    _controller = NumEditingController(number: v, formatter: _formatter());
  }

  setUp(() {
    _controller = NumEditingController(formatter: _formatter());
  });

  group('NumEditingController, br currency', () {
    setUp(() {
      _formatter = () => NumInputFormatter(
        decimalPoint: 2,
        decimalSeparator: ',',
        thousandSeparator: '.',
        signType: .showNegative,
      );
      _controller = NumEditingController(formatter: _formatter());
    });

    test('empty', () async {
      expect(_number, null);
      expect(_text, '');
    });

    test('1', () async {
      _text = '1';
      expect(_number, 0.01);
      expect(_text, '0,01');
    });

    test('12', () async {
      _text = '1';
      _text = '${_text}2';
      expect(_number, 0.12);
      expect(_text, '0,12');
    });

    test('123', () async {
      _text = '1';
      _text = '${_text}2';
      _text = '${_text}3';
      expect(_number, 1.23);
      expect(_text, '1,23');
    });

    test('1234', () async {
      _text = '1';
      _text = '${_text}2';
      _text = '${_text}3';
      _text = '${_text}4';
      expect(_number, 12.34);
      expect(_text, '12,34');
    });

    test('123 deleting', () async {
      _text = '1';
      _text = '${_text}2';
      _text = '${_text}3';
      _text = '${_text}4';
      _text = _text.substring(0, _text.length - 1);
      expect(_number, 1.23);
      expect(_text, '1,23');
    });

    test('12 deleting', () async {
      _text = '1.23';
      _text = _text.substring(0, _text.length - 1);
      expect(_number, 0.12);
      expect(_text, '0,12');
    });

    test('1 deleting', () async {
      _text = '0.12';
      _text = _text.substring(0, _text.length - 1);
      expect(_number, 0.01);
      expect(_text, '0,01');
    });

    test('0 deleting', () async {
      _text = '0.01';
      _text = _text.substring(0, _text.length - 1);
      expect(_number, 0.0);
      expect(_text, '0,00');
    });

    test('empty deleting', () async {
      _text = '0.00';
      _text = _text.substring(0, _text.length - 1);
      expect(_number, null);
      expect(_text, '');
    });
  });

  group('NumEditingController, alwaysShowDecimalPoint = false', () {
    setUp(() {
      _formatter = () => NumInputFormatter(
        canBeEmpty: false,
        decimalPoint: 2,
        decimalSeparator: ',',
        thousandSeparator: '.',
        signType: .showNegative,
        alwaysShowDecimalPoint: false,
      );
      _controller = NumEditingController(formatter: _formatter());
    });

    test('0', () async {
      expect(_number, null);
      expect(_text, '0');
    });

    test('01', () async {
      _text = '01';
      expect(_number, 1);
      expect(_text, '1');
    });

    test('1,', () async {
      setValue(1);
      _text = '1,';
      expect(_number, 1);
      expect(_text, '1,');
    });

    test('1,0', () async {
      setValue(1);
      _text = '1,';
      _text = '1,0';
      expect(_number, 1);
      expect(_text, '1,0');
    });

    test('1,01', () async {
      setValue(1);
      _text = '1,0';
      _text = '1,01';
      expect(_number, 1.01);
      expect(_text, '1,01');
    });

    test('12', () async {
      setValue(1);
      _text = '12';
      expect(_number, 12);
      expect(_text, '12');
    });

    test('12,', () async {
      setValue(12);
      _text = '12,';
      expect(_number, 12);
      expect(_text, '12,');
    });

    test('12,0', () async {
      setValue(12);
      _text = '12,0';
      expect(_number, 12);
      expect(_text, '12,0');
    });

    test('12,01', () async {
      setValue(12.0);
      _text = '12,01';
      expect(_number, 12.01);
      expect(_text, '12,01');
    });

    test('12,3', () async {
      setValue(12);
      _text = '12,3';
      expect(_number, 12.3);
      expect(_text, '12,3');
    });

    test('12,30', () async {
      setValue(12.3);
      _text = '12,30';
      expect(_number, 12.3);
      expect(_text, '12,30');
    });

    test('12,300', () async {
      setValue(12.30);
      expect(_number, 12.3);
      expect(_text, '12,3');
      _text = '12,30';
      expect(_text, '12,30');
      _text = '12,300';
      expect(_number, 12.3);
      expect(_text, '12,30');
    });

    test('123.456,', () async {
      setValue(123456);
      expect(_number, 123456);
      expect(_text, '123.456');
      _text = '123.456,';
      expect(_number, 123456);
      expect(_text, '123.456,');
    });
  });
}
