import 'dart:convert';
import 'dart:js_interop';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'client.dart';
import 'models.dart';

QuikstopEventClient createClient({required String url, required String token}) {
  return QuikstopEventWebClient(url: url, token: token);
}

class QuikstopEventWebClient implements QuikstopEventClient {
  final StreamController<QuikstopEvent> _controller = StreamController<QuikstopEvent>.broadcast();
  web.EventSource? _eventSource;
  web.EventListener? _messageListener;
  web.EventListener? _errorListener;

  QuikstopEventWebClient({required String url, required String token}) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['token'] = token;
    final sseUrl = uri.replace(queryParameters: queryParams).toString();

    try {
      _eventSource = web.EventSource(sseUrl);

      _messageListener = (web.Event event) {
        final msg = event as web.MessageEvent;
        final jsData = msg.data;
        if (jsData == null) return;

        final String rawData;
        if (jsData.isA<JSString>()) {
          rawData = (jsData as JSString).toDart;
        } else {
          rawData = jsData.toString();
        }

        if (rawData.isEmpty) return;

        try {
          final parsed = jsonDecode(rawData);
          if (parsed is Map<String, dynamic>) {
            _controller.add(QuikstopEvent.fromJson(parsed));
          }
        } catch (_) {}
      }.toJS;

      _errorListener = (web.Event event) {
        _controller.addError(Exception('Quikstop SSE Web connection error'));
      }.toJS;

      _eventSource!.addEventListener('message', _messageListener!);
      _eventSource!.addEventListener('error', _errorListener!);
    } catch (e) {
      _controller.addError(e);
    }
  }

  @override
  Stream<QuikstopEvent> get eventStream => _controller.stream;

  @override
  void close() {
    if (_eventSource != null) {
      if (_messageListener != null) {
        _eventSource!.removeEventListener('message', _messageListener!);
      }
      if (_errorListener != null) {
        _eventSource!.removeEventListener('error', _errorListener!);
      }
      _eventSource!.close();
      _eventSource = null;
    }
    _controller.close();
  }
}
