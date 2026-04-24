import 'dart:async';

class Debouncer {
  Debouncer({required int milliseconds, void Function()? action})
    : duration = Duration(milliseconds: milliseconds),
      _action = action;
  final Duration duration;
  final void Function()? _action;

  Timer? _timer;

  DebouncerState get state => _state;
  DebouncerState _state = DebouncerState.idle;

  void Function() _effectiveAction(void Function() action) {
    return () {
      _state = DebouncerState.running;
      try {
        action();
      } finally {
        _state = DebouncerState.idle;
      }
    };
  }

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, _effectiveAction(action));
    _state = DebouncerState.active;
  }

  void run() {
    assert(_action != null, 'No action provided to Debouncer');
    if (_action != null) {
      _timer?.cancel();
      _timer = Timer(duration, _effectiveAction(_action));
      _state = DebouncerState.active;
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _state = DebouncerState.idle;
  }
}

enum DebouncerState {
  idle,
  active,
  running
  ;

  bool get isIdle => this == DebouncerState.idle;
  bool get isActive => this == DebouncerState.active;
  bool get isRunning => this == DebouncerState.running;
}
