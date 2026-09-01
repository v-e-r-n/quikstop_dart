import 'client_stub.dart'
    if (dart.library.js_interop) 'client_web.dart'
    if (dart.library.io) 'client_native.dart';

import 'models.dart';

abstract class QuikstopEventClient {
  factory QuikstopEventClient({required String url, required String token}) =>
      createClient(url: url, token: token);

  Stream<QuikstopEvent> get eventStream;
  void close();
}
