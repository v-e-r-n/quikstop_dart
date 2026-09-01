import 'dart:async';
import 'package:dio/dio.dart';
import 'models.dart';

typedef TokenGetter = FutureOr<String?> Function();
typedef TokenSaver = FutureOr<void> Function(AuthTokens tokens);
typedef LogoutCallback = void Function();

/// A drop-in Dio interceptor that injects Bearer JWT access tokens and automatically
/// catches 401 Unauthorized responses to perform a refresh and replay the request.
class QuikstopAuthInterceptor extends QueuedInterceptor {
  final Dio _refreshDio;
  final Uri baseUrl;
  final String refreshPath;
  final TokenGetter getAccessToken;
  final TokenGetter getRefreshToken;
  final TokenSaver onTokenRefreshed;
  final LogoutCallback? onLogout;

  QuikstopAuthInterceptor({
    required this.baseUrl,
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.onTokenRefreshed,
    this.refreshPath = '/api/v1/auth/refresh',
    this.onLogout,
    Dio? refreshDio,
  }) : _refreshDio = refreshDio ??
            Dio(BaseOptions(
              baseUrl: baseUrl.toString(),
              contentType: 'application/json',
            ));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      onLogout?.call();
      return handler.next(err);
    }

    try {
      final refreshUrl = baseUrl.resolve(refreshPath).toString();
      final response = await _refreshDio.post(
        refreshUrl,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        onLogout?.call();
        return handler.next(err);
      }

      final tokens = AuthTokens.fromJson(data);
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        onLogout?.call();
        return handler.next(err);
      }

      await onTokenRefreshed(tokens);

      // Replay the failed request with the new access token
      err.requestOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      final retryResponse = await _refreshDio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      onLogout?.call();
      return handler.next(err);
    }
  }
}
