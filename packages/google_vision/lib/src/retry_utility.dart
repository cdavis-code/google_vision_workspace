import 'dart:math';

import 'package:dio/dio.dart';

/// Retry utility with exponential backoff for handling transient failures
class RetryUtility {
  /// Execute an operation with retry logic
  ///
  /// [operation] - The async operation to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [baseDelay] - Initial delay before first retry (default: 1 second)
  /// [maxDelay] - Maximum delay between retries (default: 30 seconds)
  /// [retryableStatusCodes] - HTTP status codes that should trigger a retry
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    List<int>? retryableStatusCodes,
  }) async {
    final codes = retryableStatusCodes ?? [408, 429, 500, 502, 503, 504];

    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on DioException catch (e) {
        lastException = e;

        // Don't retry if we've exhausted all attempts
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Don't retry if status code is not retryable
        final statusCode = e.response?.statusCode;
        if (statusCode != null && !codes.contains(statusCode)) {
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(attempt, baseDelay, maxDelay);
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but required for type safety
    throw lastException ?? StateError('Retry loop exited unexpectedly');
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(
    int attempt,
    Duration baseDelay,
    Duration maxDelay,
  ) {
    // Exponential backoff: baseDelay * 2^attempt
    final exponentialDelay = baseDelay * pow(2, attempt);

    // Add jitter (±25%) to prevent thundering herd
    final jitter = exponentialDelay * 0.25 * (Random().nextDouble() * 2 - 1);
    final delayWithJitter = exponentialDelay + jitter;

    // Cap at maxDelay
    return delayWithJitter < maxDelay ? delayWithJitter : maxDelay;
  }
}
