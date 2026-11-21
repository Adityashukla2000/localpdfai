import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/widgets/empty_state_view.dart';

void main() {
  group('EmptyStateView Widget Tests', () {
    testWidgets('Renders title, description, and triggers onAction callback',
        (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.picture_as_pdf_outlined,
              title: 'No Documents Imported',
              description: 'Import a PDF to begin.',
              actionLabel: 'Import PDF',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Documents Imported'), findsOneWidget);
      expect(find.text('Import a PDF to begin.'), findsOneWidget);
      expect(find.text('Import PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

      await tester.tap(find.text('Import PDF'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });
}
