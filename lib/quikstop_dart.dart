library quikstop_dart;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'src/auth/models.dart';
import 'src/events/client.dart';
import 'src/otp/client.dart';

// Re-export models & widgets
export 'src/auth/models.dart';
export 'src/otp/client.dart';
export 'src/events/models.dart';
export 'src/events/client.dart';
export 'src/ui/auth_card.dart';

/// The unified Quikstop client combining OTP authentication, JWT token refresh,
/// and real-time SSE event streaming.
class QuikstopClient {
  final Uri baseUrl;
  final http.Client _client;
  final QuikstopOTPClient otp;
  final String refreshPath;

  QuikstopClient({
    required this.baseUrl,
    http.Client? httpClient,
    String knockPath = '/api/v1/auth/otp/request',
    String verifyPath = '/api/v1/auth/otp/verify',
    this.refreshPath = '/api/v1/auth/refresh',
  })  : _client = httpClient ?? http.Client(),
        otp = QuikstopOTPClient(
          baseUrl: baseUrl,
          httpClient: httpClient,
          knockPath: knockPath,
          verifyPath: verifyPath,
        );

  /// Requests a passwordless verification code for [recipient].
  Future<void> knock(String recipient) => otp.knock(recipient);

  /// Verifies [code] and returns typed [AuthTokens].
  Future<AuthTokens> verify(String recipient, String code) => otp.verify(recipient, code);

  /// Verifies [code] and returns the raw response string.
  Future<String> verifyRaw(String recipient, String code) => otp.verifyRaw(recipient, code);

  /// Refreshes the session using the provided [refreshToken], returning a new [AuthTokens] pair.
  Future<AuthTokens> refresh(String refreshToken) async {
    final url = baseUrl.resolve(refreshPath);
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AuthTokens.fromJson(data);
      }
      throw QuikstopException('Invalid response format: expected JSON object');
    }

    throw QuikstopException('Token refresh failed (${response.statusCode})', statusCode: response.statusCode);
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
