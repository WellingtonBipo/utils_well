extension StringExtension on String {
  String? get firstOrNull => isNotEmpty ? this[0] : null;

  String? get nullIfEmpty => isEmpty ? null : this;

  String capitalize() => this[0].toUpperCase() + substring(1);

  String unCapitalize() => this[0].toLowerCase() + substring(1);

  String firstWord() {
    final index = indexOf(' ');
    return index == -1 ? this : substring(0, index);
  }

  String substringMax(int start, [int? end]) {
    if (end == null || end > length) return substring(start, length);
    return substring(start, end);
  }

  DateTime toParseDateTime() => DateTime.parse(this);

  DateTime? toTryParseDateTime() => DateTime.tryParse(this);

  String removeDiacritics() {
    var text = this;
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (var i = 0; i < length; i++) {
      final idx = withDia.indexOf(this[i]);
      if (idx < 0) continue;
      text = text.replaceAll(withDia[idx], withoutDia[idx]);
    }
    return text;
  }

  bool containsSanitized(String other) {
    final itemName = removeDiacritics().toLowerCase().trim();
    final searchText = other.removeDiacritics().toLowerCase().trim();
    return itemName.contains(searchText);
  }
}
