import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/auth_session.dart';
import '../models/otp_results.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

class HttpApiClient implements ApiClient {
  HttpApiClient(this.storage, {http.Client? client})
      : _client = client ?? http.Client();

  final TokenStorage storage;
  final http.Client _client;
  Future<void>? _refreshInFlight;

  Uri _uri(String path) => Uri.parse('${Env.baseUrl}$path');

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final accessToken = await storage.readAccess();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (requireAuth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final uri = _uri(path);
      if (method == 'GET') {
        return await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      }
      if (method == 'POST') {
        return await _client
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
      }
      throw const ApiException(500, 'server_error', 'Unsupported HTTP method.');
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

  Future<dynamic> _decodeBody(http.Response response) async {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _refresh() async {
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return;
    }

    _refreshInFlight = () async {
      final refresh = await storage.readRefresh();
      if (refresh == null || refresh.isEmpty) {
        await storage.clear();
        throw const ApiException(
          401,
          'token_invalid',
          'Your session has expired. Please log in again.',
        );
      }

      final response = await _send('POST', '/api/v1/auth/refresh/',
          body: {'refresh': refresh});
      final body = await _decodeBody(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final access = body['access'] as String?;
        final nextRefresh = body['refresh'] as String? ?? refresh;
        if (access == null || access.isEmpty) {
          throw const ApiException(401, 'token_invalid',
              'Your session has expired. Please log in again.');
        }
        await storage.save(access: access, refresh: nextRefresh);
        return;
      }
      await storage.clear();
      throw ApiException.fromResponse(response.statusCode, response.body);
    }();

    try {
      await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  @override
  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    final response = await _send('POST', '/api/v1/auth/otp/request/',
        body: {'phone_number': phoneNumber});
    final data = await _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return OtpRequestResult.fromJson(data as Map<String, dynamic>);
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String code,
  }) async {
    final response = await _send(
      'POST',
      '/api/v1/auth/otp/verify/',
      body: {
        'phone_number': phoneNumber,
        'request_id': requestId,
        'code': code,
      },
    );
    final data = await _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return OtpVerifyResult.fromJson(data as Map<String, dynamic>);
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }

  @override
  Future<AuthSession> setupAccount({
    required String setupToken,
    required String username,
    required String password,
  }) async {
    final response = await _send(
      'POST',
      '/api/v1/auth/setup-account/',
      body: {
        'setup_token': setupToken,
        'username': username,
        'password': password,
      },
    );
    final data = await _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final session = AuthSession.fromJson(data as Map<String, dynamic>);
      await storage.save(access: session.access, refresh: session.refresh);
      return session;
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }

  @override
  Future<AuthSession> login(
      {required String username, required String password}) async {
    final response = await _send(
      'POST',
      '/api/v1/auth/login/',
      body: {
        'username': username,
        'password': password,
      },
    );
    final data = await _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final session = AuthSession.fromJson(data as Map<String, dynamic>);
      await storage.save(access: session.access, refresh: session.refresh);
      return session;
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }

  @override
  Future<User> me() async {
    final accessToken = await storage.readAccess();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(401, 'token_invalid',
          'Your session has expired. Please log in again.');
    }

    final response = await _send('GET', '/api/v1/auth/me/', requireAuth: true);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = await _decodeBody(response);
      return User.fromJson(data as Map<String, dynamic>);
    }

    final error = ApiException.fromResponse(response.statusCode, response.body);
    if (response.statusCode == 401 &&
        (error.code == 'token_invalid' || error.code == 'not_authenticated')) {
      await _refresh();
      final retry = await _send('GET', '/api/v1/auth/me/', requireAuth: true);
      if (retry.statusCode >= 200 && retry.statusCode < 300) {
        final data = await _decodeBody(retry);
        return User.fromJson(data as Map<String, dynamic>);
      }
      final retryError =
          ApiException.fromResponse(retry.statusCode, retry.body);
      throw retryError;
    }
    throw error;
  }

  @override
  Future<void> logout() async {
    final accessToken = await storage.readAccess();
    final refreshToken = await storage.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      await storage.clear();
      return;
    }
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        await _send(
          'POST',
          '/api/v1/auth/logout/',
          body: {'refresh': refreshToken},
          requireAuth: true,
        );
      }
    } catch (_) {
      // Ignore server-side logout failures and always clear locally.
    } finally {
      await storage.clear();
    }
  }

  @override
  Future<bool> hasSession() async {
    final refresh = await storage.readRefresh();
    return refresh != null && refresh.isNotEmpty;
  }
}
