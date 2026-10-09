import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/core/theme/app_theme.dart';
import 'package:xxmi_manager/features/library/presentation/library_tab_bar.dart';

void main() {
  testWidgets(
    'slides and blends tab colors, including a mid-animation reversal',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => LibraryTabBar(
                  selectedIndex: selected,
                  onChanged: (index) => setState(() => selected = index),
                ),
              ),
            ),
          ),
        ),
      );

      final indicator = find.byKey(const ValueKey('library-tab-indicator'));
      final start = tester.getTopLeft(indicator).dx;
      Color? textColor(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      double indicatorScale() => tester
          .widget<Transform>(
            find
                .ancestor(of: indicator, matching: find.byType(Transform))
                .first,
          )
          .transform
          .storage[0];
      Color indicatorColor() =>
          (tester.widget<DecoratedBox>(indicator).decoration as BoxDecoration)
              .color!;
      expect(indicatorScale(), 1);
      expect(indicatorColor().toARGB32(), AppColors.primary.toARGB32());
      expect(textColor('Mods'), AppColors.onPrimary);
      expect(textColor('Download'), AppColors.textSecondary);

      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final midpoint = tester.getTopLeft(indicator).dx;
      expect(indicatorScale(), closeTo(0.85, 0.001));
      expect(
        indicatorColor().toARGB32(),
        Color.lerp(AppColors.primary, Colors.black, 0.20)!.toARGB32(),
      );
      expect(midpoint, greaterThan(start));
      expect(midpoint, lessThan(start + 126));
      expect(textColor('Download'), isNot(AppColors.textSecondary));
      expect(textColor('Download'), isNot(AppColors.onPrimary));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.archive_outlined)).color,
        textColor('Download'),
      );

      await tester.tap(find.text('Mods'));
      await tester.pump();
      expect(tester.getTopLeft(indicator).dx, closeTo(midpoint, 0.01));
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.getTopLeft(indicator).dx, start);
      expect(indicatorScale(), 1);
      expect(indicatorColor().toARGB32(), AppColors.primary.toARGB32());
      expect(textColor('Mods'), AppColors.onPrimary);

      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.getTopLeft(indicator).dx, start + 126);
      expect(indicatorScale(), 1);
      expect(indicatorColor().toARGB32(), AppColors.primary.toARGB32());
      expect(textColor('Mods'), AppColors.textSecondary);
      expect(textColor('Download'), AppColors.onPrimary);
    },
  );
}
