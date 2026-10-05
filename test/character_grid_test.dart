import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/core/character_catalog.dart';
import 'package:xxmi_manager/features/library/presentation/library_page.dart';

void main() {
  testWidgets('wheel keeps scrolling while hovering an avatar', (tester) async {
    tester.view.physicalSize = const Size(800, 632);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterGrid(
            characters: zzzCharacterFolders
                .map((name) => '$name (default)')
                .toList(),
            zipCounts: const {},
            loading: false,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    final avatar = tester.getCenter(find.byType(HeroAvatar).first);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.moveTo(avatar);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(Tooltip), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.sendEventToBinding(
        PointerScrollEvent(position: avatar, scrollDelta: const Offset(0, 150)),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(150 * i));
    }
    await mouse.removePointer();
  });

  testWidgets('keeps a skin immediately after its character across rows', (
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
              'Astra Yao (default)',
              'Astra Yao - Chandelier',
            ],
            zipCounts: const {},
            loading: false,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final defaultPosition = tester.getTopLeft(find.text('Astra Yao'));
    final skinPosition = tester.getTopLeft(find.text('Astra Yao - Chandelier'));
    expect(skinPosition.dy, greaterThan(defaultPosition.dy));
    expect(skinPosition.dx, lessThan(defaultPosition.dx));
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

  testWidgets('fills the last slot instead of leaving a gap before a skin', (
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
              'Corin Wickes (default)',
              'Dialyn (default)',
              'Ellen Joe (default)',
              'Ellen Joe - On Campus',
            ],
            zipCounts: const {},
            loading: false,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final corin = tester.getTopLeft(find.text('Corin Wickes'));
    final dialyn = tester.getTopLeft(find.text('Dialyn'));
    final ellen = tester.getTopLeft(find.text('Ellen Joe'));
    final skin = tester.getTopLeft(find.text('Ellen Joe - On Campus'));
    expect(ellen.dy, corin.dy);
    expect(ellen.dy, dialyn.dy);
    expect(ellen.dx, greaterThan(dialyn.dx));
    expect(skin.dy, greaterThan(ellen.dy));
  });
}
