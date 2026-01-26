import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:utils_well/utils_well.dart';

class Command<S, F, V> extends ChangeNotifier {
  Command(
    FutureOr<Result<S, F>> Function(V value)? action, {
    FutureOr<V> Function()? getValue,
    CommandResult<S, F>? initialResult,
  }) : _getValue = getValue,
       _action = action {
    _result = initialResult ?? CommandResultInitial<S, F>();
  }

  final FutureOr<Result<S, F>> Function(V)? _action;
  final FutureOr<V> Function()? _getValue;

  var _disposed = false;

  CommandResult<S, F>? _lastResult;
  late CommandResult<S, F> _result;

  CommandResult<S, F>? get lastResult => _lastResult;
  CommandResult<S, F> get result => _result;

  set result(CommandResult<S, F> r) {
    _lastResult = _result;
    _result = r;
    notifyListeners();
  }

  bool get isInitial => _result.isInitial;
  bool get isLoading => _result.isLoading;
  bool get isSuccess => _result.isSuccess;
  bool get isFailure => _result.isFailure;

  Future<void> call([V? value]) async {
    if (_action == null) {
      throw const Error(
        'No action was provided for this command. Either'
        ' provide an action when creating the command or override call method',
      );
    }
    final vString = V.toString().toLowerCase();
    if (value == null &&
        _getValue == null &&
        !vString.endsWith('?') &&
        vString != 'void' &&
        vString != 'never' &&
        vString != 'dynamic' &&
        vString != 'null') {
      throw ArgumentError(
        'Either provide a value when calling the command or provide a'
        ' getValue function when creating the command.',
      );
    }
    _lastResult = _result;
    _result = _result.copyToLoading();
    notifyListeners();
    final actionResult = await _action(value ?? await _getValue!());
    if (_disposed) return;
    _lastResult = _result;
    _result = actionResult.fold(
      (success) => _result.copyToSuccess(data: success),
      (failure) => _result.copyToFailure(failure: failure),
    );
    notifyListeners();
  }

  void setInitial({(S?,)? data, (F?,)? failure}) =>
      result = _result.copyToInitial(data: data, failure: failure);

  void setLoading({(S?,)? data, (F?,)? failure}) =>
      result = _result.copyToLoading(data: data, failure: failure);

  void setSuccess({required S data, (F?,)? failure}) =>
      result = _result.copyToSuccess(data: data, failure: failure);

  void setFailure({required F failure, (S?,)? data}) =>
      result = _result.copyToFailure(failure: failure, data: data);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

abstract interface class CommandResult<D, E> extends _Result<D, E>
    with _CommandResultFold<D, E> {
  const CommandResult._({super.data, super.failure});
}

class _Result<D, E> extends Equatable {
  const _Result({this.data, this.failure});

  final D? data;
  final E? failure;

  @override
  List<Object?> get props => [data, failure];
}

class CommandResultInitial<D, E> extends CommandResult<D, E> {
  const CommandResultInitial({super.data, super.failure}) : super._();
}

class CommandResultLoading<D, E> extends CommandResult<D, E> {
  const CommandResultLoading({super.data, super.failure}) : super._();
}

class CommandResultSuccess<D, E> extends CommandResult<D, E> {
  const CommandResultSuccess({required D super.data, super.failure})
    : super._();

  @override
  D get data => super.data as D;

  static const empty = CommandResultSuccess<void, void>(data: null);
}

class CommandResultFailure<D, E> extends CommandResult<D, E> {
  const CommandResultFailure({required E super.failure, super.data})
    : super._();

  @override
  E get failure => super.failure as E;

  static const empty = CommandResultFailure<void, void>(failure: null);
}

mixin _CommandResultFold<D, E> on _Result<D, E> {
  bool get isInitial => this is CommandResultInitial;
  bool get isLoading => this is CommandResultLoading;
  bool get isSuccess => this is CommandResultSuccess;
  bool get isFailure => this is CommandResultFailure;

  T fold<T>({
    required T Function(CommandResultInitial<D, E> result) onInitial,
    required T Function(CommandResultLoading<D, E> result) onLoading,
    required T Function(CommandResultSuccess<D, E> result) onSuccess,
    required T Function(CommandResultFailure<D, E> result) onFailure,
  }) =>
      foldAnyOrNull(
            onInitial: onInitial,
            onLoading: onLoading,
            onSuccess: onSuccess,
            onFailure: onFailure,
          )
          as T;

  T foldAny<T>({
    required T Function(CommandResult<D, E> result) onAny,
    T Function(CommandResultInitial<D, E> result)? onInitial,
    T Function(CommandResultLoading<D, E> result)? onLoading,
    T Function(CommandResultSuccess<D, E> result)? onSuccess,
    T Function(CommandResultFailure<D, E> result)? onFailure,
  }) =>
      foldAnyOrNull(
            onAny: onAny,
            onInitial: onInitial,
            onLoading: onLoading,
            onSuccess: onSuccess,
            onFailure: onFailure,
          )
          as T;

  T? foldAnyOrNull<T>({
    T Function(CommandResult<D, E> result)? onAny,
    T Function(CommandResultInitial<D, E> result)? onInitial,
    T Function(CommandResultLoading<D, E> result)? onLoading,
    T Function(CommandResultSuccess<D, E> result)? onSuccess,
    T Function(CommandResultFailure<D, E> result)? onFailure,
  }) {
    final t = this as CommandResult<D, E>;
    if (t is CommandResultInitial<D, E> && onInitial != null) {
      return onInitial(t);
    }
    if (t is CommandResultLoading<D, E> && onLoading != null) {
      return onLoading(t);
    }
    if (t is CommandResultSuccess<D, E> && onSuccess != null) {
      return onSuccess(t);
    }
    if (t is CommandResultFailure<D, E> && onFailure != null) {
      return onFailure(t);
    }
    return onAny?.call(t);
  }

  CommandResult<D, E> copyWith({
    (D?,)? data,
    (E?,)? failure,
  }) => fold(
    onInitial: (s) => s.copyToInitial(data: data, failure: failure),
    onLoading: (s) => s.copyToLoading(data: data, failure: failure),
    onSuccess: (s) => s.copyToSuccess(
      failure: failure,
      data: data == null ? s.data : (data.$1 is D ? data.$1 as D : s.data),
    ),
    onFailure: (s) => s.copyToFailure(
      data: data,
      failure: failure == null
          ? s.failure
          : (failure.$1 is E ? failure.$1 as E : s.failure),
    ),
  );

  CommandResultInitial<D, E> copyToInitial({(D?,)? data, (E?,)? failure}) =>
      CommandResultInitial<D, E>(
        data: data._or(this.data),
        failure: failure._or(this.failure),
      );

  CommandResultLoading<D, E> copyToLoading({(D?,)? data, (E?,)? failure}) =>
      CommandResultLoading<D, E>(
        data: data._or(this.data),
        failure: failure._or(this.failure),
      );

  CommandResultSuccess<D, E> copyToSuccess({required D data, (E?,)? failure}) =>
      CommandResultSuccess<D, E>(
        data: data,
        failure: failure._or(this.failure),
      );

  CommandResultFailure<D, E> copyToFailure({required E failure, (D?,)? data}) =>
      CommandResultFailure<D, E>(
        data: data._or(this.data),
        failure: failure,
      );

  CommandResultSuccess<D, E>? get successOrNull =>
      foldAnyOrNull(onSuccess: (result) => result);

  CommandResultInitial<D, E>? get initialOrNull =>
      foldAnyOrNull(onInitial: (result) => result);

  CommandResultLoading<D, E>? get loadingOrNull =>
      foldAnyOrNull(onLoading: (result) => result);

  CommandResultFailure<D, E>? get failureOrNull =>
      foldAnyOrNull(onFailure: (result) => result);
}

extension _R<T> on (T?,)? {
  T? _or(T? or) => this == null ? or : this!.$1;
}
