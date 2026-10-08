import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/features/library/data/library_repository.dart';
import 'package:xxmi_manager/features/library/presentation/rename_entry_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    Future<void> Function(String) onRename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RenameEntryDialog(
                  entry: File('/tmp/Outfit.zip'),
                  onRename: onRename,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('keeps the archive extension and closes after rename', (
    tester,
  ) async {
    String? renamed;
    await openDialog(tester, (name) async => renamed = name);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Outfit',
    );
    expect(find.text('.zip'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'New outfit');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(renamed, 'New outfit.zip');
    expect(find.byType(RenameEntryDialog), findsNothing);
  });

  testWidgets('shows collisions inline and lets the user retry', (
    tester,
  ) async {
    final names = <String>[];
    await openDialog(tester, (name) async {
      names.add(name);
      if (name == 'Duplicate.zip') {
        throw const RenameEntryException(RenameEntryFailure.alreadyExists);
      }
    });
    await tester.enterText(find.byType(TextField), 'Duplicate');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('A file or folder with this name already exists.'),
      findsOneWidget,
    );
    expect(find.byType(RenameEntryDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Unique');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();
    expect(names, ['Duplicate.zip', 'Unique.zip']);
    expect(find.byType(RenameEntryDialog), findsNothing);
  });
}
