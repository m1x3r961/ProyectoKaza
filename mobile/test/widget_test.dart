import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart' as app;

void main() {
  testWidgets('missing configuration stops startup with an explicit error',
      (tester) async {
    await app.main();
    await tester.pump();
    expect(
        find.text(
            'No se pudo iniciar KAZA. Revisa la configuración y la conexión.'),
        findsOneWidget);
    expect(find.byType(app.KazaApp), findsNothing);
  });
}
