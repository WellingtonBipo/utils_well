import 'dart:async';

extension FutureExtension<T> on Future<T> {
  Future<T> awaitUntil(bool Function() test) async {
    T result;
    try {
      result = await this;
    } catch (e) {
      rethrow;
    } finally {
      while (!test()) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    return result;
  }

  Future<T> awaitAtLeast({
    int milliseconds = 1000,
    bool doAwait = true,
  }) async {
    if (!doAwait) return this;

    final completer = Completer<void>();
    final duration = Duration(milliseconds: milliseconds);
    unawaited(Future.delayed(duration).then((_) => completer.complete()));
    try {
      final result = await this;
      if (completer.isCompleted) return result;
      await completer.future;
      return result;
    } catch (e) {
      if (!completer.isCompleted) completer.complete();
      rethrow;
    }
  }
}
