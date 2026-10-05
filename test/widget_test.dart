import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/app/xxmi_app.dart';

void main() {
  testWidgets('builds the app shell', (tester) async {
    await tester.pumpWidget(const XxmiApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
