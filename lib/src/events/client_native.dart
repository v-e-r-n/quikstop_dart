import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'client.dart';
import 'models.dart';

QuikstopEventClient createClient({required String url, required String token}) {
  return QuikstopEventNativeClient(url: url, token: token);
}

class QuikstopEventNativeClient implements QuikstopEventClient {
  final StreamController<QuikstopEvent> _controller = StreamController<QuikstopEvent>.broadcast();
  HttpClient? _client;
  bool _closed = false;

  QuikstopEventNativeClient({required String url, required String token}) {
    _connect(url, token);
  }

  Future<void> _connect(String url, String token) async {
    while (!_closed) {
      try {
        _client = HttpClient();
        final request = await _client!.getUrl(Uri.parse(url));
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.set('Accept', 'text/event-stream');
        request.headers.set('Cache-Control', 'no-cache');

        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('Invalid status code: ${response.statusCode}');
        }

        final linesStream = response
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in linesStream) {
          if (_closed) break;
          if (line.startsWith('data:')) {
            final rawData = line.substring(5).trim();
            if (rawData.isEmpty) continue;
            try {
              final parsed = jsonDecode(rawData);
              if (parsed is Map<String, dynamic>) {
                _controller.add(QuikstopEvent.fromJson(parsed));
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        if (_closed) break;
        _controller.addError(e);
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  @override
  Stream<QuikstopEvent> get eventStream => _controller.stream;

  @override
  void close() {
    _closed = true;
    _client?.close(force: true);
    _controller.close();
  }
}
