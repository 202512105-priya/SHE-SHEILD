import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _storageChannel = MethodChannel('com.sheshield.she_shield/storage');
String? _inMemoryToken;
String? _inMemoryServerHost;

String? getWebOriginHost() => null;

Future<({String? authToken, String? serverHost})> initPersistentStorage() async {
  try {
    final res = await _storageChannel.invokeMethod<Map<dynamic, dynamic>>('loadState');
    if (res != null) {
      final tok = res['authToken']?.toString().trim();
      final host = res['customServerHost']?.toString().trim();
      _inMemoryToken = (tok == null || tok.isEmpty) ? null : tok;
      _inMemoryServerHost = (host == null || host.isEmpty) ? null : host;
    }
  } catch (_) {}
  return (authToken: _inMemoryToken, serverHost: _inMemoryServerHost);
}

void saveSessionTokenStorage(String? token) {
  final norm = (token == null || token.trim().isEmpty) ? null : token.trim();
  _inMemoryToken = norm;
  unawaited(
    _storageChannel.invokeMethod('saveAuthToken', {'token': norm ?? ''}).catchError((_) => null),
  );
}

String? loadSessionTokenStorage() => _inMemoryToken;

void saveServerHostStorage(String? host) {
  final norm = (host == null || host.trim().isEmpty) ? null : host.trim();
  _inMemoryServerHost = norm;
  unawaited(
    _storageChannel.invokeMethod('saveServerHost', {'host': norm ?? ''}).catchError((_) => null),
  );
}

String? loadServerHostStorage() => _inMemoryServerHost;

Future<({int statusCode, String body})> platformHttpRequest({
  required String method,
  required String url,
  Map<String, String>? headers,
  String? jsonBody,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(url);
    final upper = method.toUpperCase();
    final HttpClientRequest request;
    if (upper == 'POST') {
      request = await client.postUrl(uri).timeout(timeout);
    } else if (upper == 'DELETE') {
      request = await client.deleteUrl(uri).timeout(timeout);
    } else {
      request = await client.getUrl(uri).timeout(timeout);
    }

    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });

    if (jsonBody != null) {
      request.headers.contentType = ContentType.json;
      final bodyBytes = utf8.encode(jsonBody);
      request.headers.contentLength = bodyBytes.length;
      request.add(bodyBytes);
    }

    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return (statusCode: response.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}

Future<({int statusCode, String body})> platformUploadBinary({
  required String url,
  required Uint8List bytes,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(url);
    final request = await client.postUrl(uri).timeout(timeout);
    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });
    request.headers.contentLength = bytes.length;
    request.add(bytes);

    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return (statusCode: response.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}

Future<({int statusCode, Uint8List bytes})> platformDownloadBytes({
  required String url,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 25),
}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(url);
    final request = await client.getUrl(uri).timeout(timeout);
    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });
    final response = await request.close().timeout(timeout);
    final chunks = <int>[];
    await for (final part in response) {
      chunks.addAll(part);
    }
    return (statusCode: response.statusCode, bytes: Uint8List.fromList(chunks));
  } finally {
    client.close(force: true);
  }
}
