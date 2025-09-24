/// A Result type for handling success and error cases in a type-safe manner.
/// 
/// This implementation follows the functional programming pattern of using
/// a sealed type to represent either a successful result or an error.
/// It's similar to Rust's Result<T, E> or Haskell's Either type.
sealed class Result<T, E> {
  const Result();

  /// Creates a successful result containing a value
  const factory Result.success(T value) = Success<T, E>;

  /// Creates an error result containing an error
  const factory Result.error(E error) = Error<T, E>;

  /// Returns true if this result represents a success
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this result represents an error
  bool get isError => this is Error<T, E>;

  /// Gets the success value, throwing if this is an error
  T get value => switch (this) {
    Success(value: final v) => v,
    Error(error: final e) => throw StateError('Called value on error: $e'),
  };

  /// Gets the error value, throwing if this is a success
  E get error => switch (this) {
    Success(value: final v) => throw StateError('Called error on success: $v'),
    Error(error: final e) => e,
  };

  /// Gets the success value or returns null if this is an error
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Error() => null,
  };

  /// Gets the error value or returns null if this is a success
  E? get errorOrNull => switch (this) {
    Success() => null,
    Error(error: final e) => e,
  };

  /// Transforms the success value using the provided function
  /// 
  /// If this is an error, returns the error unchanged.
  /// If this is a success, applies the function to the value.
  Result<U, E> map<U>(U Function(T) mapper) => switch (this) {
    Success(value: final v) => Result.success(mapper(v)),
    Error(error: final e) => Result.error(e),
  };

  /// Transforms the error value using the provided function
  /// 
  /// If this is a success, returns the success unchanged.
  /// If this is an error, applies the function to the error.
  Result<T, F> mapError<F>(F Function(E) mapper) => switch (this) {
    Success(value: final v) => Result.success(v),
    Error(error: final e) => Result.error(mapper(e)),
  };

  /// Chains another operation that returns a Result
  /// 
  /// If this is an error, returns the error unchanged.
  /// If this is a success, applies the function to the value.
  Result<U, E> flatMap<U>(Result<U, E> Function(T) mapper) => switch (this) {
    Success(value: final v) => mapper(v),
    Error(error: final e) => Result.error(e),
  };

  /// Returns the success value or the provided default value
  T getOrElse(T defaultValue) => switch (this) {
    Success(value: final v) => v,
    Error() => defaultValue,
  };

  /// Returns the success value or the result of calling the provider function
  T getOrElseGet(T Function() provider) => switch (this) {
    Success(value: final v) => v,
    Error() => provider(),
  };

  /// Performs an action based on whether this is a success or error
  U fold<U>(
    U Function(T) onSuccess,
    U Function(E) onError,
  ) => switch (this) {
    Success(value: final v) => onSuccess(v),
    Error(error: final e) => onError(e),
  };

  /// Performs a side effect if this is a success, returns this unchanged
  Result<T, E> onSuccess(void Function(T) action) {
    if (this case Success(value: final v)) {
      action(v);
    }
    return this;
  }

  /// Performs a side effect if this is an error, returns this unchanged
  Result<T, E> onError(void Function(E) action) {
    if (this case Error(error: final e)) {
      action(e);
    }
    return this;
  }

  /// Converts this Result to a Future
  Future<T> toFuture() => switch (this) {
    Success(value: final v) => Future.value(v),
    Error(error: final e) => Future.error(e as Object),
  };

  /// Creates a Result from a Future, catching any exceptions
  static Future<Result<T, Object>> fromFuture<T>(Future<T> future) async {
    try {
      final value = await future;
      return Result.success(value);
    } catch (error) {
      return Result.error(error);
    }
  }

  /// Creates a Result by executing a function, catching any exceptions
  static Result<T, Object> fromFunction<T>(T Function() function) {
    try {
      final value = function();
      return Result.success(value);
    } catch (error) {
      return Result.error(error);
    }
  }

  @override
  String toString() => switch (this) {
    Success(value: final v) => 'Success($v)',
    Error(error: final e) => 'Error($e)',
  };

  @override
  bool operator ==(Object other) => switch (this) {
    Success(value: final v) => other is Success && other.value == v,
    Error(error: final e) => other is Error && other.error == e,
  };

  @override
  int get hashCode => switch (this) {
    Success(value: final v) => Object.hash('Success', v),
    Error(error: final e) => Object.hash('Error', e),
  };
}

/// Represents a successful result containing a value
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  /// The successful value
  final T value;
}

/// Represents an error result containing an error
final class Error<T, E> extends Result<T, E> {
  const Error(this.error);

  /// The error value
  final E error;
}

/// Utility extensions for working with nullable values and Results
extension NullableResult<T> on T? {
  /// Converts a nullable value to a Result
  /// 
  /// Returns Success if the value is non-null, Error with the provided error otherwise.
  Result<T, E> toResult<E>(E error) => this != null 
      ? Result.success(this as T)
      : Result.error(error);
}

/// Utility extensions for working with Future<Result>
extension FutureResult<T, E> on Future<Result<T, E>> {
  /// Maps the success value asynchronously
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T) mapper) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => Result.success(await mapper(v)),
      Error(error: final e) => Result.error(e),
    };
  }

  /// Chains another asynchronous operation that returns a Result
  Future<Result<U, E>> flatMapAsync<U>(
    Future<Result<U, E>> Function(T) mapper,
  ) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => await mapper(v),
      Error(error: final e) => Result.error(e),
    };
  }
}