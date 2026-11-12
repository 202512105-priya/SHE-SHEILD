import 'dart:async';
import 'dart:typed_data';

String? getWebOriginHost() => null;

Future<({String? authToken, String? serverHost})> initPersistentStorage() async =>
    (authToken: null, serverHost: null);

void saveSessionTokenStorage(String? token) {}

String? loadSessionTokenStorage() => null;

void saveServerHostStorage(String? host) {}

String? loadServerHostStorage() => null;

Future<({int statusCode, String body})> platformHttpRequest({
  required String method,
  required String url,
  Map<String, String>? headers,
  String? jsonBody,
  Duration timeout = const Duration(seconds: 4),
}) {
  throw UnsupportedError('HTTP transport not supported on this platform');
}

Future<({int statusCode, String body})> platformUploadBinary({
  required String url,
  required Uint8List bytes,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) {
  throw UnsupportedError('Binary upload not supported on this platform');
}

Future<({int statusCode, Uint8List bytes})> platformDownloadBytes({
  required String url,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) {
  throw UnsupportedError('Binary download not supported on this platform');
}
