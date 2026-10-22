import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chdc_counselling/core/api/api_exception.dart';
import 'package:chdc_counselling/core/api/http_api_client.dart';
import 'package:chdc_counselling/core/storage/token_storage.dart';

Map<String, dynamic> userJson({String username = 'amina_b'}) => {
      'id': '00000000-0000-4000-8000-0000000000aa',
      'username': username,
      'phone_number': '+2348031234567',
      'date_joined': '2026-10-21T09:00:00Z',
    };

Map<String, dynamic> sessionJson({String username = 'amina_b'}) => {
      'access': 'access-token',
      'refresh': 'refresh-token',
      'user': userJson(username: username),
    };

http.Response jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
    });

void main() {
  test('sends contract paths, snake_case bodies, and required headers',
      () async {
    final storage = InMemoryTokenStorage();
    await storage.save(access: 'access-token', refresh: 'refresh-token');
    final seen = <http.Request>[];
    final client = HttpApiClient(
      storage,
      client: MockClient((request) async {
        seen.add(request);
        switch (request.url.path) {
          case '/api/v1/auth/otp/request/':
            return jsonResponse({
              'request_id': 'request-id',
              'message': 'sent',
              'expires_in': 300,
              'resend_after': 60,
            });
          case '/api/v1/auth/otp/verify/':
            return jsonResponse({'setup_token': 'setup-token', 'expires_in': 600});
          case '/api/v1/auth/setup-account/':
          case '/api/v1/auth/login/':
            return jsonResponse(sessionJson());
          case '/api/v1/auth/me/':
            return jsonResponse(userJson());
          case '/api/v1/auth/refresh/':
            return jsonResponse({
              'access': 'new-access',
              'refresh': 'new-refresh',
            });
          case '/api/v1/auth/logout/':
            return http.Response('', 204);
          default:
            return http.Response('', 404);
        }
      }),
    );

    await client.requestOtp('+2348031234567');
    await client.verifyOtp(
      phoneNumber: '+2348031234567',
      requestId: 'request-id',
      code: '123456',
    );
    await client.setupAccount(
      setupToken: 'setup-token',
      username: 'Amina_B',
      password: 'S3cure!pass',
    );
    await client.login(username: 'Amina_B', password: 'S3cure!pass');
    await client.me();
    await client.logout();

    expect(
      seen.map((request) => request.url.path),
      [
        '/api/v1/auth/otp/request/',
        '/api/v1/auth/otp/verify/',
        '/api/v1/auth/setup-account/',
        '/api/v1/auth/login/',
        '/api/v1/auth/me/',
        '/api/v1/auth/logout/',
      ],
    );
    for (final request in seen) {
      expect(request.headers['ngrok-skip-browser-warning'], 'true');
      expect(request.headers['content-type'], 'application/json');
      expect(request.url.path.endsWith('/'), isTrue);
    }
    expect(jsonDecode(seen[0].body), {'phone_number': '+2348031234567'});
    expect(jsonDecode(seen[1].body), {
      'phone_number': '+2348031234567',
      'request_id': 'request-id',
      'code': '123456',
    });
    expect(jsonDecode(seen[2].body), {
      'setup_token': 'setup-token',
      'username': 'amina_b',
      'password': 'S3cure!pass',
    });
    expect(jsonDecode(seen[3].body), {
      'username': 'amina_b',
      'password': 'S3cure!pass',
    });
    expect(seen[4].headers['authorization'], 'Bearer access-token');
    expect(jsonDecode(seen[5].body), {'refresh': 'refresh-token'});
    expect(seen[5].headers['authorization'], 'Bearer access-token');
  });

  test('parses API error details and uses a safe fallback for invalid JSON',
      () {
    final error = ApiException.fromResponse(
      429,
      jsonEncode({
        'error': {
          'code': 'rate_limited',
          'message': 'Wait',
          'retry_after': 42,
          'fields': {'phone_number': ['Invalid phone']},
        },
      }),
    );
    expect(error.code, 'rate_limited');
    expect(error.retryAfter, 42);
    expect(error.fieldError('phone_number'), 'Invalid phone');

    final invalidOtp = ApiException.fromResponse(
      400,
      '{"error":{"code":"invalid_otp","message":"Wrong","attempts_remaining":4}}',
    );
    expect(invalidOtp.attemptsRemaining, 4);
    final fallback = ApiException.fromResponse(502, '<html>');
    expect(fallback.code, 'server_error');
    expect(fallback.message, 'Something went wrong. Please try again.');
  });

  test('refreshes expired access and stores rotated tokens before retry',
      () async {
    final storage = InMemoryTokenStorage();
    await storage.save(access: 'expired-access', refresh: 'old-refresh');
    var meCalls = 0;
    final api = HttpApiClient(
      storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/me/') {
          meCalls++;
          if (meCalls == 1) {
            return jsonResponse({
              'error': {
                'code': 'token_invalid',
                'message': 'Expired',
              },
            }, status: 401);
          }
          expect(request.headers['authorization'], 'Bearer new-access');
          return jsonResponse(userJson());
        }
        if (request.url.path == '/api/v1/auth/refresh/') {
          expect(jsonDecode(request.body), {'refresh': 'old-refresh'});
          return jsonResponse({
            'access': 'new-access',
            'refresh': 'new-refresh',
          });
        }
        return http.Response('', 404);
      }),
    );

    expect((await api.me()).username, 'amina_b');
    expect(await storage.readAccess(), 'new-access');
    expect(await storage.readRefresh(), 'new-refresh');
    expect(meCalls, 2);
  });

  test('failed refresh clears tokens and returns token_invalid', () async {
    final storage = InMemoryTokenStorage();
    await storage.save(access: 'expired-access', refresh: 'bad-refresh');
    final api = HttpApiClient(
      storage,
      client: MockClient((request) async => jsonResponse({
        'error': {'code': 'token_invalid', 'message': 'Expired'},
      }, status: 401)),
    );

    await expectLater(
      api.me(),
      throwsA(isA<ApiException>().having(
        (error) => error.code,
        'code',
        'token_invalid',
      )),
    );
    expect(await storage.readRefresh(), isNull);
  });

  test('concurrent expired requests share one refresh request', () async {
    final storage = InMemoryTokenStorage();
    await storage.save(access: 'expired-access', refresh: 'old-refresh');
    var refreshCalls = 0;
    var meCalls = 0;
    final api = HttpApiClient(
      storage,
      client: MockClient((request) async {
        expect(request.headers['ngrok-skip-browser-warning'], 'true');
        if (request.url.path == '/api/v1/auth/me/') {
          meCalls++;
          if ((request.headers['authorization'] ?? '').endsWith('expired-access')) {
            return jsonResponse({
              'error': {'code': 'token_invalid', 'message': 'Expired'},
            }, status: 401);
          }
          return jsonResponse(userJson());
        }
        if (request.url.path == '/api/v1/auth/refresh/') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return jsonResponse({
            'access': 'new-access',
            'refresh': 'new-refresh',
          });
        }
        return http.Response('', 404);
      }),
    );

    await Future.wait([api.me(), api.me()]);
    expect(refreshCalls, 1);
    expect(meCalls, 4);
  });

  test('maps client connection failures to network_error', () async {
    final api = HttpApiClient(
      InMemoryTokenStorage(),
      client: MockClient(
        (request) async => throw http.ClientException('connection failed'),
      ),
    );

    await expectLater(
      api.requestOtp('+2348031234567'),
      throwsA(isA<ApiException>().having(
        (error) => error.code,
        'code',
        'network_error',
      )),
    );
  });

  test('logout clears local tokens even if server fails', () async {
    final storage = InMemoryTokenStorage();
    await storage.save(access: 'access-token', refresh: 'refresh-token');
    final api = HttpApiClient(
      storage,
      client: MockClient(
        (request) async => http.Response('unavailable', 500),
      ),
    );

    await expectLater(api.logout(), completes);
    expect(await storage.readAccess(), isNull);
    expect(await storage.readRefresh(), isNull);
  });
}
