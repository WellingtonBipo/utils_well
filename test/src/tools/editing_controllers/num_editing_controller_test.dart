import 'package:flutter_test/flutter_test.dart';
import 'package:utils_well/utils_well.dart';

void main() {
  NumInputFormatter formatter() => NumInputFormatter(
    canBeEmpty: false,
    decimalPoint: 2,
    decimalSeparator: ',',
    thousandSeparator: '.',
    signType: .showNegative,
    alwaysShowDecimalPoint: false,
  );
  late NumEditingController controller;

  void setValue(num v) {
    controller = NumEditingController(number: v, formatter: formatter());
  }

  setUp(() {
    controller = NumEditingController(formatter: formatter());
  });

  test('0', () async {
    expect(controller.number, null);
    expect(controller.text, '0');
  });

  test('01', () async {
    controller.text = '01';
    expect(controller.number, 1);
    expect(controller.text, '1');
  });

  test('1,', () async {
    setValue(1);
    controller.text = '1,';
    expect(controller.number, 1);
    expect(controller.text, '1,');
  });

  test('1,0', () async {
    setValue(1);
    controller.text = '1,';
    controller.text = '1,0';
    expect(controller.number, 1);
    expect(controller.text, '1,0');
  });

  test('1,01', () async {
    setValue(1);
    controller.text = '1,0';
    controller.text = '1,01';
    expect(controller.number, 1.01);
    expect(controller.text, '1,01');
  });

  test('12', () async {
    setValue(1);
    controller.text = '12';
    expect(controller.number, 12);
    expect(controller.text, '12');
  });

  test('12,', () async {
    setValue(12);
    controller.text = '12,';
    expect(controller.number, 12);
    expect(controller.text, '12,');
  });

  test('12,0', () async {
    setValue(12);
    controller.text = '12,0';
    expect(controller.number, 12);
    expect(controller.text, '12,0');
  });

  test('12,01', () async {
    setValue(12.0);
    controller.text = '12,01';
    expect(controller.number, 12.01);
    expect(controller.text, '12,01');
  });

  test('12,3', () async {
    setValue(12);
    controller.text = '12,3';
    expect(controller.number, 12.3);
    expect(controller.text, '12,3');
  });

  test('12,30', () async {
    setValue(12.3);
    controller.text = '12,30';
    expect(controller.number, 12.3);
    expect(controller.text, '12,30');
  });

  test('12,300', () async {
    setValue(12.30);
    expect(controller.number, 12.3);
    expect(controller.text, '12,3');
    controller.text = '12,30';
    expect(controller.text, '12,30');
    controller.text = '12,300';
    expect(controller.number, 12.3);
    expect(controller.text, '12,30');
  });

  test('123.456,', () async {
    setValue(123456);
    expect(controller.number, 123456);
    expect(controller.text, '123.456');
    controller.text = '123.456,';
    expect(controller.number, 123456);
    expect(controller.text, '123.456,');
  });
}
