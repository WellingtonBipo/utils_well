import 'package:meta/meta.dart';

abstract mixin class Notifier {
  final _listeners = <void Function()>{};

  @protected
  @visibleForTesting
  void notifyListeners({
    void Function(List<(Object, StackTrace)>)? handleErrors,
  }) {
    final errors = <(Object, StackTrace)>[];

    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        errors.add((e, StackTrace.current));
      }
    }

    if (errors.isEmpty) return;
    if (handleErrors != null) handleErrors(errors);
    throw NotifierError(errors);
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  bool get hasListeners => _listeners.isNotEmpty;
}

class NotifierError extends Error {
  NotifierError(this.errors);

  final List<(Object, StackTrace)> errors;

  @override
  String toString() => 'NotifierException:\n$errors';
}
