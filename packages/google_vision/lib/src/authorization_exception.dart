class AuthorizationException implements Exception {
  final String msg;
  final Exception? _innerError;

  const AuthorizationException([this.msg = '', Exception? innerError])
    : _innerError = innerError;

  @override
  String toString() => 'Authorization error: $msg';

  /// Internal detailed error message for logging purposes only.
  /// Do not expose to end users.
  String toDetailedString() => 'Authorization error: $msg\n\n$_innerError';
}
