import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/profile/screens/delete_account_screen.dart';
import 'package:mobile/features/profile/services/account_api.dart';

class _FailingAccountApi extends AccountApi {
  int calls = 0;
  @override
  Future<void> deleteAccount() async {
    calls++;
    throw ApiException('Cuenta restringida.', 403);
  }
}

void main() {
  test('deleteAccount posts the typed confirmation with the session token',
      () async {
    late http.Request sent;
    final api = AccountApi(
        api: ApiClient(
            accessToken: () => 'token',
            clientFactory: () => MockClient((request) async {
                  sent = request;
                  return http.Response('{"success":true}', 200);
                })));
    await api.deleteAccount();
    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/account/delete');
    expect(sent.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(sent.body), {'confirm': 'ELIMINAR'});
  });

  testWidgets('delete requires typing ELIMINAR and reports failures',
      (tester) async {
    final api = _FailingAccountApi();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: DeleteAccountScreen(api: api))));

    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(TextButton, 'Eliminar cuenta');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('delete-account-confirmation')), 'eliminar');
    await tester.pump();
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('delete-account-confirmation')), 'ELIMINAR');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(api.calls, 1);
    expect(find.text('No se pudo eliminar la cuenta: Cuenta restringida.'),
        findsOneWidget);
  });

  testWidgets('deactivate explains it is not available yet', (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: DeleteAccountScreen())));
    await tester.tap(find.text('Desactivar cuenta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('todavía no está disponible'), findsOneWidget);
  });
}
