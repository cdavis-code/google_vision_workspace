import 'package:dio/dio.dart';
import 'package:flutter_loggy_dio/flutter_loggy_dio.dart';
import 'package:google_vision/google_vision.dart';
import 'package:loggy/loggy.dart';

import 'authorization_exception.dart';

/// Secure HTTP interceptor that redacts sensitive headers from logs
class _SecureLoggyDioInterceptor extends LoggyDioInterceptor {
  _SecureLoggyDioInterceptor({
    super.requestBody,
    super.responseBody,
    super.requestLevel,
    super.responseLevel,
    super.errorLevel,
  });

  static const _sensitiveHeaders = {
    'authorization',
    'x-goog-api-key',
    'x-goog-user-project',
    'cookie',
    'x-api-key',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Create a copy of headers with sensitive values redacted
    final safeOptions = RequestOptions(
      method: options.method,
      path: options.path,
      headers: options.headers.map(
        (key, value) => MapEntry(
          key,
          _sensitiveHeaders.contains(key.toLowerCase()) ? '[REDACTED]' : value,
        ),
      ),
      data: options.data,
      queryParameters: options.queryParameters,
    );
    super.onRequest(safeOptions, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Redact sensitive headers from response logs
    final safeResponse = Response(
      requestOptions: response.requestOptions,
      data: response.data,
      headers: Headers.fromMap(
        response.headers.map.map(
          (key, values) => MapEntry(
            key,
            _sensitiveHeaders.contains(key.toLowerCase())
                ? ['[REDACTED]']
                : values,
          ),
        ),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: response.extra,
    );
    super.onResponse(safeResponse, handler);
  }
}

/// Integrates Google Vision features, including painter labeling, face, logo,
/// and landmark detection, optical character recognition (OCR), and detection
/// of explicit content, into applications.
class GoogleVision with UiLoggy {
  static final GoogleVision _instance = GoogleVision._internal();

  final dio = Dio();
  DateTime _tokenExpiry = DateTime(2010, 0, 0);

  late final _imagesClient = ImagesClient(dio);
  late final _filesClient = FilesClient(dio);

  static const accept = 'application/json';
  static const contentType = 'application/json; charset=UTF-8';

  TokenGenerator? tokenGenerator;
  String? _apiKey;
  String? _token;

  GoogleVisionImage get image => GoogleVisionImage(this, _imagesClient);

  GoogleVisionFile get file => GoogleVisionFile(this, _filesClient);

  set apiKey(String apiKey) => _apiKey = apiKey;

  // Private constructor
  GoogleVision._internal();

  factory GoogleVision([LogLevel logLevel = LogLevel.off]) {
    if (logLevel != LogLevel.off) {
      _instance.dio.interceptors.add(
        _SecureLoggyDioInterceptor(
          requestBody: true,
          responseBody: true,
          requestLevel: logLevel,
          responseLevel: logLevel,
          errorLevel: logLevel,
        ),
      );
    }

    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(showColors: true),
      logOptions: LogOptions(logLevel),
    );

    return _instance;
  }

  /// Authenticate using an API key.
  GoogleVision withApiKey(
    String apiKey, {
    Map<String, String>? additionalHeaders,
  }) {
    this.apiKey = apiKey;

    if (additionalHeaders != null) {
      dio.options.headers.addAll(additionalHeaders);
    }

    return this;
  }

  /// Authenticate using the supplied token generator
  Future<GoogleVision> withGenerator(TokenGenerator generator) async {
    tokenGenerator = generator;

    await confirmToken();

    return this;
  }

  /// Authenticated with JWT.
  Future<GoogleVision> withJwt(
    String credentials, [
    String scope = 'https://www.googleapis.com/auth/cloud-platform',
  ]) async {
    tokenGenerator = JwtGenerator(
      credentials: credentials,
      scope: scope,
      dio: dio,
    );

    await confirmToken();

    return this;
  }

  void setAuthHeader() {
    if (_token != null) {
      dio.options.headers['authorization'] = 'Bearer $_token';
    }

    if (_apiKey != null) {
      dio.options.headers['X-Goog-Api-Key'] = _apiKey;
    }
  }

  /// Clear all authentication credentials and tokens.
  /// Call this method when logging out or when credentials are no longer needed.
  void clearCredentials() {
    _apiKey = null;
    _token = null;
    tokenGenerator = null;
    _tokenExpiry = DateTime(2010, 0, 0);
    dio.options.headers.remove('authorization');
    dio.options.headers.remove('X-Goog-Api-Key');
  }

  Future<void> confirmToken() async {
    if (tokenGenerator == null) {
      throw AuthorizationException(
        'Token generator not configured. '
        'Call withApiKey(), withJwt(), or withGenerator() first.',
      );
    } else {
      if (_tokenExpiry.isBefore(DateTime.now())) {
        final tokenData = await tokenGenerator!.generate();

        _token = tokenData.accessToken;

        _tokenExpiry = DateTime.now().add(
          Duration(seconds: tokenData.expiresIn),
        );
      }
    }
  }
}
