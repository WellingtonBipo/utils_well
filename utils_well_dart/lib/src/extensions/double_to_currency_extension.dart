extension DoubleToCurrency on double {
  String toCurrency({
    bool showCurrency = true,
    bool showMinusSymbol = true,
    int decimal = 2,
    String currencySymbol = r'R$ ',
    String decimalSeparator = ',',
    String thousandSeparator = '.',
  }) {
    final value = abs();
    final parts = value.toStringAsFixed(decimal + 1).split('.');
    var string = parts[0];

    for (var i = string.length - 1; i >= 0; i = i - 3) {
      if (i + 1 == string.length) continue;
      string = string.substring(0, i + 1) +
          thousandSeparator +
          string.substring(i + 1);
    }

    if (decimal > 0) {
      string += decimalSeparator + parts[1].substring(0, parts[1].length - 1);
    }
    if (isNegative) string = showMinusSymbol ? '-$string' : string;
    if (showCurrency) string = currencySymbol + string;
    return string;
  }
}
