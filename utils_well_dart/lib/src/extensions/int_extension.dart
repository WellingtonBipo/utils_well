extension IntExtension on int {
  Future<void> waitMilliseconds() =>
      Future.delayed(Duration(milliseconds: this));
}
