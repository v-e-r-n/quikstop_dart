import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quikstop_dart/quikstop_dart.dart';

void main() {
  group('QuikstopClient', () {
    test('knock sends recipient', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request as http.Request;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final qs = QuikstopClient(
        baseUrl: Uri.parse('https://api.example.com'),
        httpClient: mockClient,
      );

      await qs.knock('test@example.com');
      expect(capturedRequest.url.path, '/api/v1/auth/otp/request');
      final body = jsonDecode(capturedRequest.body);
      expect(body['recipient'], 'test@example.com');
    });

    test('verify parses AuthTokens successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'access-jwt-token',
            'refresh_token': 'refresh-jwt-token',
            'expires_at': '2026-10-01T00:00:00Z',
          }),
          200,
        );
      });

      final qs = QuikstopClient(
        baseUrl: Uri.parse('https://api.example.com'),
        httpClient: mockClient,
      );

      final tokens = await qs.verify('test@example.com', '123456');
      expect(tokens.accessToken, 'access-jwt-token');
      expect(tokens.refreshToken, 'refresh-jwt-token');
      expect(tokens.expiresAt, isNotNull);
    });

    test('verify throws on invalid code', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'invalid_code'}),
          401,
        );
      });

      final qs = QuikstopClient(
        baseUrl: Uri.parse('https://api.example.com'),
        httpClient: mockClient,
      );

      expect(
        () => qs.verify('test@example.com', '000000'),
        throwsA(isA<InvalidCodeException>()),
      );
    });

    test('refresh parses refreshed AuthTokens', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request as http.Request;
        return http.Response(
          jsonEncode({
            'token': 'new-access-jwt-token',
            'refresh_token': 'new-refresh-jwt-token',
          }),
          200,
        );
      });

      final qs = QuikstopClient(
        baseUrl: Uri.parse('https://api.example.com'),
        httpClient: mockClient,
      );

      final tokens = await qs.refresh('old-refresh-jwt-token');
      expect(capturedRequest.url.path, '/api/v1/auth/refresh');
      final body = jsonDecode(capturedRequest.body);
      expect(body['refresh_token'], 'old-refresh-jwt-token');
      expect(tokens.accessToken, 'new-access-jwt-token');
      expect(tokens.refreshToken, 'new-refresh-jwt-token');
    });
  });
}
