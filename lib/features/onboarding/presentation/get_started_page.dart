import '../../../core/theme/app_theme.dart';
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
    final x = await getDirectoryPath(confirmButtonText: 'Chọn thư mục Mods');
    if (x != null) setState(() => mods = x);
  }

  Future<void> pickDownload() async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thư mục Download'),
        content: const Text('Bạn đã có sẵn thư mục Download hay muốn tạo mới?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Tạo mới'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Đã có sẵn'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice) {
      final x = await getDirectoryPath(
        confirmButtonText: 'Chọn thư mục Download',
      );
      if (x != null) setState(() => download = x);
      return;
    }
    final parent = await getDirectoryPath(
      confirmButtonText: 'Chọn nơi tạo thư mục',
    );
    if (parent == null) return;
    if (!mounted) return;
    final controller = TextEditingController(text: 'ZZZ_Download');
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tạo thư mục Download'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên thư mục'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Tạo'),
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
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'XXMI Manager',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quản lý mods Zenless Zone Zero theo từng nhân vật.',
                style: TextStyle(color: AppColors.textSubtle, fontSize: 16),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: SetupCard(
                      title: 'Thư mục Mods',
                      subtitle:
                          mods ?? 'Chọn thư mục chứa các mod đang sử dụng',
                      icon: Icons.folder_special_outlined,
                      onTap: pickMods,
                      selected: mods != null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SetupCard(
                      title: 'Thư mục Download',
                      subtitle: download ?? 'Chọn hoặc tạo nơi lưu file ZIP',
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
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: const Text('Bắt đầu quản lý'),
                ),
              ),
            ],
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
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 170,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
