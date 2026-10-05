import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/features/library/presentation/library_page.dart';

void main() {
  testWidgets('shows files as grid cards and keeps the right-click action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 632);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entries = <FileSystemEntity>[
      File('/tmp/Test.zip'),
      Directory('/tmp/Installed mod'),
      File('/tmp/notes.txt'),
      File('/tmp/Another.zip'),
    ];
    FileSystemEntity? selectedEntry;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileEntryGrid(
            entries: entries,
            onContextMenu: (_, entry) => selectedEntry = entry,
          ),
        ),
      ),
    );

    expect(find.text('Test.zip'), findsOneWidget);
    expect(find.text('ZIP'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Test.zip')).dy,
      tester.getTopLeft(find.text('Installed mod')).dy,
    );
    expect(
      tester.getTopLeft(find.text('Installed mod')).dy,
      tester.getTopLeft(find.text('notes.txt')).dy,
    );
    expect(
      tester.getTopLeft(find.text('Another.zip')).dy,
      greaterThan(tester.getTopLeft(find.text('Test.zip')).dy),
    );

    await tester.tap(
      find.text('Test.zip'),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    expect(selectedEntry, same(entries.first));
  });
}
