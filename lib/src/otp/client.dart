import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/models.dart';

class QuikstopException implements Exception {
  final String message;
  final int? statusCode;

  QuikstopException(this.message, {this.statusCode});

  @override
  String toString() => 'QuikstopException: $message (statusCode: $statusCode)';
}

class InvalidCodeException extends QuikstopException {
  InvalidCodeException() : super('The verification code entered is invalid.', statusCode: 401);
}

class MaxRetriesExceededException extends QuikstopException {
  MaxRetriesExceededException() : super('Maximum retry attempts exceeded.', statusCode: 403);
}

class CodeExpiredException extends QuikstopException {
  CodeExpiredException() : super('The verification code has expired.', statusCode: 410);
}

class RecipientNotFoundException extends QuikstopException {
  RecipientNotFoundException() : super('No active code request found for recipient.', statusCode: 404);
}

class QuikstopOTPClient {
  final Uri baseUrl;
  final http.Client _client;
  final String knockPath;
  final String verifyPath;

  QuikstopOTPClient({
    required this.baseUrl,
    this.knockPath = '/api/v1/auth/otp/request',
    this.verifyPath = '/api/v1/auth/otp/verify',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// Requests a verification code to be generated and delivered to the [recipient].
  Future<void> knock(String recipient) async {
    final url = baseUrl.resolve(knockPath);
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipient': recipient, 'email': recipient}),
    );

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }
  }

  /// Verifies the [code] sent to the [recipient].
  /// Returns typed [AuthTokens] on success.
  Future<AuthTokens> verify(String recipient, String code) async {
    final rawBody = await verifyRaw(recipient, code);
    final data = jsonDecode(rawBody);
    if (data is Map<String, dynamic>) {
      return AuthTokens.fromJson(data);
    }
    throw QuikstopException('Invalid response format: expected JSON object');
  }

  /// Verifies the [code] sent to the [recipient] and returns the raw response body.
  Future<String> verifyRaw(String recipient, String code) async {
    final url = baseUrl.resolve(verifyPath);
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipient': recipient, 'code': code, 'otp': code}),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      _handleErrorResponse(response);
      throw QuikstopException('Verification failed', statusCode: response.statusCode);
    }
  }

  void _handleErrorResponse(http.Response response) {
    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('error')) {
        final error = body['error'];
        if (error == 'invalid_code') {
          throw InvalidCodeException();
        } else if (error == 'max_retries_exceeded') {
          throw MaxRetriesExceededException();
        } else if (error == 'code_expired') {
          throw CodeExpiredException();
        } else if (error == 'not_found' || error == 'user_not_found') {
          throw RecipientNotFoundException();
        }
        errorMessage = error.toString();
      }
    } on TypeError {
    } on FormatException {
    }

    throw QuikstopException(errorMessage, statusCode: response.statusCode);
  }
}
