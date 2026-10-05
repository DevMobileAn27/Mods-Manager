import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/features/library/presentation/animated_search_field.dart';

void main() {
  testWidgets(
    'collapses after 3 seconds, expands on hover, stays open with text',
    (tester) async {
      var query = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedSearchField(onChanged: (s) => query = s),
            ),
          ),
        ),
      );

      final search = find.byKey(const ValueKey('library-search'));
      expect(tester.getSize(search).width, 250);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 320));
      expect(tester.getSize(search).width, 42);
      expect(find.byIcon(Icons.search), findsOneWidget);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(0, 0));
      await mouse.moveTo(tester.getCenter(search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      expect(tester.getSize(search).width, 250);

      await tester.enterText(find.byType(TextField), 'Astra');
      expect(query, 'Astra');
      await mouse.moveTo(const Offset(0, 0));
      await tester.pump(const Duration(seconds: 4));
      expect(tester.getSize(search).width, 250);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 320));
      expect(tester.getSize(search).width, 42);
    },
  );
}
