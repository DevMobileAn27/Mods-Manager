import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_background.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/character_catalog.dart';

class SetupPage extends StatefulWidget {
  final Future<void> Function(String, String) onDone;
  const SetupPage({super.key, required this.onDone});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String? mods, download;
  bool busy = false;
  Future<void> pickMods() async {
    final x = await getDirectoryPath(
      confirmButtonText: AppStrings.of(context).pickMods,
    );
    if (x != null) setState(() => mods = x);
  }

  Future<void> pickDownload() async {
    final strings = AppStrings.of(context);
    final choice = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(strings.downloadFolder),
        content: Text(strings.downloadChoice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(strings.createNew),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(strings.alreadyExists),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice) {
      final x = await getDirectoryPath(confirmButtonText: strings.pickDownload);
      if (x != null) setState(() => download = x);
      return;
    }
    final parent = await getDirectoryPath(
      confirmButtonText: strings.pickParent,
    );
    if (parent == null) return;
    if (!mounted) return;
    final controller = TextEditingController(text: 'ZZZ_Download');
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(strings.createDownload),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.folderName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: Text(strings.create),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final dir = Directory(p.join(parent, titleCaseFolder(name)));
    await dir.create(recursive: true);
    setState(() => download = dir.path);
  }

  Future<void> finish() async {
    if (mods == null || download == null) return;
    setState(() => busy = true);
    await Directory(mods!).create(recursive: true);
    await Directory(download!).create(recursive: true);
    await widget.onDone(mods!, download!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.widgets_outlined,
                  color: AppColors.primary,
                  size: 42,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Visual Mods Manager',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of(context).appDescription,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: SetupCard(
                        title: AppStrings.of(context).modsFolder,
                        subtitle: mods ?? AppStrings.of(context).modsFolderHint,
                        icon: Icons.folder_special_outlined,
                        onTap: pickMods,
                        selected: mods != null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SetupCard(
                        title: AppStrings.of(context).downloadFolder,
                        subtitle:
                            download ??
                            AppStrings.of(context).downloadFolderHint,
                        icon: Icons.archive_outlined,
                        onTap: pickDownload,
                        selected: download != null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: (mods != null && download != null && !busy)
                        ? finish
                        : null,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(AppStrings.of(context).getStarted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SetupCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  const SetupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.selected,
  });
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: 170,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 36,
            color: selected ? AppColors.primary : AppColors.iconMuted,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSubtle),
          ),
        ],
      ),
    ),
  );
}
