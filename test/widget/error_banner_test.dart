import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/widgets/error_banner.dart';

void main() {
  group('ErrorBanner Widget Tests', () {
    testWidgets('Displays error message, triggers onRetry and onDismiss',
        (WidgetTester tester) async {
      bool retryClicked = false;
      bool dismissClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Failed to extract PDF text',
              onRetry: () => retryClicked = true,
              onDismiss: () => dismissClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to extract PDF text'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryClicked, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(dismissClicked, isTrue);
    });
  });
}
