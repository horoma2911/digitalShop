import 'package:flutter_test/flutter_test.dart';
import 'package:gouanzouh/main.dart';

void main() {
  testWidgets('Counter removal smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SalesApp());

    // Verify that login screen is shown (since no user is logged in)
    expect(find.text('Login'), findsWidgets);
  });
}
