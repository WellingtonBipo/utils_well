extension DateTimeExtension on DateTime {
  DateTime get onlyDate =>
      (isUtc ? DateTime.utc : DateTime.new)(year, month, day);

  bool isBetween(
    DateTime start,
    DateTime end, {
    bool sameStartMoment = true,
    bool sameEndMoment = true,
  }) {
    if (isAtSameMomentAs(start) && sameStartMoment) return true;
    if (isAtSameMomentAs(end) && sameEndMoment) return true;
    if (isBefore(start)) return false;
    if (isAfter(end)) return false;
    return true;
  }

  bool isAfterNow() => isAfter(isUtc ? DateTime.now().toUtc() : DateTime.now());

  bool isBeforeNow() =>
      isBefore(isUtc ? DateTime.now().toUtc() : DateTime.now());
}
