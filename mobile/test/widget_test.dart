import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/app/app.dart';

void main() {
  testWidgets('App onboarding smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EsquiloSpeakApp(),
      ),
    );

    // Verify that onboarding screen shows greeting message.
    expect(find.textContaining('EsquiloSpeak'), findsWidgets);
    expect(find.text('Bắt đầu ngay'), findsOneWidget);
  });
}
