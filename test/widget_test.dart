import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/presentation/widgets/privacy_notice.dart';

void main() {
  testWidgets('Privacy disclosure is available before sign-in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PrivacyNotice())),
    );

    expect(find.text('Privacy & data use'), findsOneWidget);

    await tester.tap(find.text('Privacy & data use'));
    await tester.pumpAndSettle();

    expect(find.text('Your data in SpendWise'), findsOneWidget);
    expect(
      find.textContaining('Optional AI assistance is off by default'),
      findsOneWidget,
    );
    expect(find.text('Full privacy policy'), findsOneWidget);
  });
}
