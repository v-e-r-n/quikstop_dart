library quikstop_dart;

import 'package:http/http.dart' as http;
import 'src/auth/interceptor.dart';
import 'src/auth/models.dart';
import 'src/events/client.dart';
import 'src/otp/client.dart';

// Re-export models & widgets
export 'src/auth/models.dart';
export 'src/auth/interceptor.dart';
export 'src/otp/client.dart';
export 'src/events/models.dart';
export 'src/events/client.dart';
export 'src/ui/auth_card.dart';

/// The unified Quikstop client combining OTP authentication, Dio interceptor,
/// and real-time SSE event streaming.
class QuikstopClient {
  final Uri baseUrl;
  final QuikstopOTPClient otp;

  QuikstopClient({
    required this.baseUrl,
    http.Client? httpClient,
    String knockPath = '/api/v1/auth/otp/request',
    String verifyPath = '/api/v1/auth/otp/verify',
  }) : otp = QuikstopOTPClient(
          baseUrl: baseUrl,
          httpClient: httpClient,
          knockPath: knockPath,
          verifyPath: verifyPath,
        );

  /// Requests a passwordless verification code for [recipient].
  Future<void> knock(String recipient) => otp.knock(recipient);

  /// Verifies [code] and returns typed [AuthTokens].
  Future<AuthTokens> verify(String recipient, String code) => otp.verify(recipient, code);

  /// Creates a drop-in [QuikstopAuthInterceptor] for Dio.
  QuikstopAuthInterceptor createAuthInterceptor({
    required TokenGetter getAccessToken,
    required TokenGetter getRefreshToken,
    required TokenSaver onTokenRefreshed,
    String refreshPath = '/api/v1/auth/refresh',
    LogoutCallback? onLogout,
  }) {
    return QuikstopAuthInterceptor(
      baseUrl: baseUrl,
      refreshPath: refreshPath,
      getAccessToken: getAccessToken,
      getRefreshToken: getRefreshToken,
      onTokenRefreshed: onTokenRefreshed,
      onLogout: onLogout,
    );
  }

  /// Opens a cross-platform SSE connection to the backend event stream.
  QuikstopEventClient createEventClient({
    required String token,
    String eventsPath = '/api/v1/events',
  }) {
    final sseUrl = baseUrl.resolve(eventsPath).toString();
    return QuikstopEventClient(url: sseUrl, token: token);
  }
}
