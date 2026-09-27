import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_client.dart';

void main() {
  test('protected operations without session never reach the network',
      () async {
    final api = ApiClient(
        accessToken: () => null,
        clientFactory: () => throw StateError('Unexpected network request'));
    await expectLater(api.request('/api/listings', method: 'POST'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
  });
  test('retries preserve the caller key and use the current token', () async {
    var token = 'first';
    final requests = <http.Request>[];
    final api = ApiClient(
        accessToken: () => token,
        clientFactory: () => MockClient((request) async {
              requests.add(request);
              return http.Response('{"id":"persisted"}', 200);
            }));
    await api.request('/api/listings',
        method: 'POST', key: 'stable-request-key', body: {'title': 'Casa'});
    token = 'refreshed';
    await api.request('/api/listings',
        method: 'POST', key: 'stable-request-key', body: {'title': 'Casa'});
    expect(requests[0].headers['Idempotency-Key'],
        requests[1].headers['Idempotency-Key']);
    expect(requests[1].headers['Authorization'], 'Bearer refreshed');
    expect(requests[0].body, requests[1].body);
  });
  test('a server failure stays failed and public reads send no token',
      () async {
    final api = ApiClient(
        accessToken: () => throw StateError('Unexpected session access'),
        clientFactory: () => MockClient((request) async {
              expect(request.headers.containsKey('Authorization'), false);
              return http.Response('{"message":"Servicio no disponible"}', 503);
            }));
    await expectLater(api.request('/api/catalog', authenticated: false),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)));
  });
}
