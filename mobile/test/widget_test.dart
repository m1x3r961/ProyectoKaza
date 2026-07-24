import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('KazaApp initialization smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KazaApp(),
      ),
    );

    // Verify that KazaApp loads without crashing.
    expect(find.byType(KazaApp), findsOneWidget);
  });
}
