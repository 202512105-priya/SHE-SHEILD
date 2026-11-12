import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('fetch')
external JSPromise<JSObject> _jsFetch(JSString url, [JSObject? options]);

@JS('window.location.hostname')
external JSString get _windowHostname;

@JS('window.sessionStorage')
external JSObject get _sessionStorage;

@JS('window.localStorage')
external JSObject get _localStorage;

const String _tokenStorageKey = 'she_shield_session_token';
const String _serverHostStorageKey = 'she_shield_server_host';

String? getWebOriginHost() {
  try {
    final host = _windowHostname.toDart.trim();
    return host.isEmpty ? null : host;
  } catch (_) {
    return null;
  }
}

Future<({String? authToken, String? serverHost})> initPersistentStorage() async {
  return (authToken: loadSessionTokenStorage(), serverHost: loadServerHostStorage());
}

void saveSessionTokenStorage(String? token) {
  try {
    if (token == null || token.trim().isEmpty) {
      _sessionStorage.callMethod<JSAny?>('removeItem'.toJS, _tokenStorageKey.toJS);
    } else {
      _sessionStorage.callMethod<JSAny?>('setItem'.toJS, _tokenStorageKey.toJS, token.trim().toJS);
    }
  } catch (_) {}
}

String? loadSessionTokenStorage() {
  try {
    final val = _sessionStorage.callMethod<JSAny?>('getItem'.toJS, _tokenStorageKey.toJS);
    if (val == null || val.isUndefinedOrNull) return null;
    final str = (val as JSString).toDart.trim();
    return str.isEmpty ? null : str;
  } catch (_) {
    return null;
  }
}

void saveServerHostStorage(String? host) {
  try {
    if (host == null || host.trim().isEmpty) {
      _localStorage.callMethod<JSAny?>('removeItem'.toJS, _serverHostStorageKey.toJS);
    } else {
      _localStorage.callMethod<JSAny?>('setItem'.toJS, _serverHostStorageKey.toJS, host.trim().toJS);
    }
  } catch (_) {}
}

String? loadServerHostStorage() {
  try {
    final val = _localStorage.callMethod<JSAny?>('getItem'.toJS, _serverHostStorageKey.toJS);
    if (val == null || val.isUndefinedOrNull) return null;
    final str = (val as JSString).toDart.trim();
    return str.isEmpty ? null : str;
  } catch (_) {
    return null;
  }
}

Future<({int statusCode, String body})> platformHttpRequest({
  required String method,
  required String url,
  Map<String, String>? headers,
  String? jsonBody,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final options = JSObject();
  options['method'] = method.toUpperCase().toJS;

  final jsHeaders = JSObject();
  bool hasHeaders = false;
  if (headers != null) {
    headers.forEach((key, value) {
      jsHeaders[key] = value.toJS;
      hasHeaders = true;
    });
  }
  if (jsonBody != null) {
    jsHeaders['Content-Type'] = 'application/json'.toJS;
    hasHeaders = true;
    options['body'] = jsonBody.toJS;
  }
  if (hasHeaders) {
    options['headers'] = jsHeaders;
  }

  final response = await _jsFetch(url.toJS, options).toDart.timeout(timeout);
  final status = (response['status'] as JSNumber).toDartInt;
  final textPromise = response.callMethod<JSPromise<JSString>>('text'.toJS);
  final body = (await textPromise.toDart.timeout(timeout)).toDart;
  return (statusCode: status, body: body);
}

Future<({int statusCode, String body})> platformUploadBinary({
  required String url,
  required Uint8List bytes,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) async {
  final options = JSObject();
  options['method'] = 'POST'.toJS;
  if (headers != null && headers.isNotEmpty) {
    final jsHeaders = JSObject();
    headers.forEach((key, value) {
      jsHeaders[key] = value.toJS;
    });
    options['headers'] = jsHeaders;
  }
  options['body'] = bytes.toJS;

  final response = await _jsFetch(url.toJS, options).toDart.timeout(timeout);
  final status = (response['status'] as JSNumber).toDartInt;
  final textPromise = response.callMethod<JSPromise<JSString>>('text'.toJS);
  final body = (await textPromise.toDart.timeout(timeout)).toDart;
  return (statusCode: status, body: body);
}

Future<({int statusCode, Uint8List bytes})> platformDownloadBytes({
  required String url,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) async {
  final options = JSObject();
  options['method'] = 'GET'.toJS;
  if (headers != null && headers.isNotEmpty) {
    final jsHeaders = JSObject();
    headers.forEach((key, value) {
      jsHeaders[key] = value.toJS;
    });
    options['headers'] = jsHeaders;
  }
  final response = await _jsFetch(url.toJS, options).toDart.timeout(timeout);
  final status = (response['status'] as JSNumber).toDartInt;
  final abPromise = response.callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS);
  final ab = await abPromise.toDart.timeout(timeout);
  return (statusCode: status, bytes: ab.toDart.asUint8List());
}
