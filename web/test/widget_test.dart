// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/main.dart';

void main() {
  testWidgets('Nova ERP smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
