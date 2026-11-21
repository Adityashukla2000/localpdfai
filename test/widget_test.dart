import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard renders child and responds to onTap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            onTap: () {
              tapped = true;
            },
            child: const Text('Sample Document Tile'),
          ),
        ),
      ),
    );

    expect(find.text('Sample Document Tile'), findsOneWidget);

    await tester.tap(find.text('Sample Document Tile'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
