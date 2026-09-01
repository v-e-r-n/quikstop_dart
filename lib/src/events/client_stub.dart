import 'client.dart';

QuikstopEventClient createClient({required String url, required String token}) =>
    throw UnsupportedError('Cannot create a QuikstopEventClient without dart:html or dart:io.');
