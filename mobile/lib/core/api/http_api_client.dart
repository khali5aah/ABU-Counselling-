import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../models/auth_session.dart';
import '../models/otp_results.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

class HttpApiClient implements ApiClient {
  HttpApiClient(this._storage, {http.Client? client})
      : _client = client ?? http.Client();

  final TokenStorage _storage;
  final http.Client _client;
  Future<void>? _refreshFuture;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
  static const _sessionExpired = ApiException(
    statusCode: 401,
    code: 'token_invalid',
    message: 'Your session has expired. Please log in again.',
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    final headers = <String, String>{..._headers};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    final request = http.Request(method, Uri.parse('${Env.baseUrl}$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamed).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
      if (response.statusCode == 204 || response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          statusCode: 500,
          code: 'server_error',
          message: 'Something went wrong. Please try again.',
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException.networkError;
    } on TimeoutException {
      throw ApiException.networkError;
    } on http.ClientException {
      throw ApiException.networkError;
    } on HandshakeException {
      throw ApiException.networkError;
    }
  }

  @override
  Future<OtpRequestResult> requestOtp(String phoneNumber) async =>
      OtpRequestResult.fromJson(await _request(
        'POST',
        '/auth/otp/request/',
        body: {'phone_number': phoneNumber},
      ));

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String code,
  }) async =>
      OtpVerifyResult.fromJson(await _request(
        'POST',
        '/auth/otp/verify/',
        body: {
          'phone_number': phoneNumber,
          'request_id': requestId,
          'code': code,
        },
      ));

  @override
  Future<AuthSession> setupAccount({
    required String setupToken,
    required String username,
    required String password,
  }) async {
    final session = AuthSession.fromJson(await _request(
      'POST',
      '/auth/setup-account/',
      body: {
        'setup_token': setupToken,
        'username': username.trim().toLowerCase(),
        'password': password,
      },
    ));
    await _storage.save(access: session.access, refresh: session.refresh);
    return session;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final session = AuthSession.fromJson(await _request(
      'POST',
      '/auth/login/',
      body: {'username': username.trim().toLowerCase(), 'password': password},
    ));
    await _storage.save(access: session.access, refresh: session.refresh);
    return session;
  }

  @override
  Future<User> me() async {
    var access = await _storage.readAccess();
    try {
      return User.fromJson(
        await _request('GET', '/auth/me/', accessToken: access ?? ''),
      );
    } on ApiException catch (error) {
      if (error.statusCode != 401 ||
          (error.code != 'token_invalid' &&
              error.code != 'not_authenticated')) {
        rethrow;
      }
      await _refresh();
      access = await _storage.readAccess();
      return User.fromJson(
        await _request('GET', '/auth/me/', accessToken: access ?? ''),
      );
    }
  }

  Future<void> _refresh() {
    final active = _refreshFuture;
    if (active != null) return active;

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    });
  }

  Future<void> _performRefresh() async {
    try {
      final refreshToken = await _storage.readRefresh();
      if (refreshToken == null) throw _sessionExpired;
      final response = await _request(
        'POST',
        '/auth/refresh/',
        body: {'refresh': refreshToken},
      );
      await _storage.save(
        access: response['access'] as String,
        refresh: response['refresh'] as String,
      );
    } on Object {
      await _storage.clear();
      throw _sessionExpired;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refresh = await _storage.readRefresh();
      if (refresh != null) {
        final access = await _storage.readAccess();
        await _request(
          'POST',
          '/auth/logout/',
          body: {'refresh': refresh},
          accessToken: access ?? '',
        );
      }
    } on Object {
      // Clearing local credentials is required even when the server is unavailable.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<bool> hasSession() async => await _storage.readRefresh() != null;
}
