import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/common.dart';

void main() {
  testWidgets('RatingBadge shows the rating label', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RatingBadge(rating: 'excellent'))));
    expect(find.text('Excellent'), findsOneWidget);
  });
}
