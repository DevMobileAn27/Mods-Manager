import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/localization/app_strings.dart';
import '../data/library_repository.dart';

class RenameEntryDialog extends StatefulWidget {
  final FileSystemEntity entry;
  final Future<void> Function(String name) onRename;

  const RenameEntryDialog({
    super.key,
    required this.entry,
    required this.onRename,
  });

  @override
  State<RenameEntryDialog> createState() => _RenameEntryDialogState();
}

class _RenameEntryDialogState extends State<RenameEntryDialog> {
  late final String originalName = p.basename(widget.entry.path);
  late final String extension = widget.entry is File
      ? p.extension(originalName)
      : '';
  late final controller =
      TextEditingController(
          text: originalName.substring(
            0,
            originalName.length - extension.length,
          ),
        )
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: originalName.length - extension.length,
        );
  bool saving = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving) return;
    final stem = controller.text.trim();
    final name = '$stem$extension';
    if (stem.isEmpty || !LibraryRepository.isValidEntryName(name)) {
      setState(() => error = AppStrings.of(context).invalidEntryName);
      return;
    }
    if (name == originalName) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onRename(name);
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      setState(() {
        saving = false;
        error = failure is RenameEntryException
            ? switch (failure.reason) {
                RenameEntryFailure.invalidName => strings.invalidEntryName,
                RenameEntryFailure.alreadyExists => strings.duplicateEntryName,
              }
            : strings.renameError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text(strings.rename),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            autofocus: true,
            enabled: !saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
            decoration: InputDecoration(
              labelText: strings.newName,
              suffixText: extension.isEmpty ? null : extension,
              errorText: error,
              errorMaxLines: 3,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: saving ? null : submit,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.rename),
          ),
        ],
      ),
    );
  }
}
