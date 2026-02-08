import 'dart:async';

class Debouncer {
  Debouncer({required int milliseconds, void Function()? action})
    : duration = Duration(milliseconds: milliseconds),
      _action = action;
  final Duration duration;
  final void Function()? _action;

  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void run() {
    assert(_action != null, 'No action provided to Debouncer');
    if (_action != null) {
      _timer?.cancel();
      _timer = Timer(duration, _action);
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
