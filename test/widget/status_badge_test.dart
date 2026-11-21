import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/widgets/status_badge.dart';

void main() {
  group('StatusBadge Widget Tests', () {
    testWidgets('Renders label and icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Ready Offline',
              type: StatusType.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Ready Offline'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('Renders small variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Page 3',
              type: StatusType.info,
              isSmall: true,
            ),
          ),
        ),
      );

      expect(find.text('Page 3'), findsOneWidget);
    });
  });
}
