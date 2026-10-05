import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/features/library/presentation/library_page.dart';

void main() {
  testWidgets('keeps Astra Yao and her skin adjacent on the grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 632);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterGrid(
            characters: const [
              'Anby Demara (default)',
              'Anton Ivanov (default)',
              'Asaba Harumasa (default)',
              'Astra Yao (default)',
              'Astra Yao - Chandelier',
            ],
            loading: false,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final defaultPosition = tester.getTopLeft(find.text('Astra Yao'));
    final skinPosition = tester.getTopLeft(find.text('Astra Yao - Chandelier'));
    expect(skinPosition.dy, defaultPosition.dy);
    expect(skinPosition.dx, greaterThan(defaultPosition.dx));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/characters/astra_yao/chandelier.webp',
      ),
      findsOneWidget,
    );
  });
}
