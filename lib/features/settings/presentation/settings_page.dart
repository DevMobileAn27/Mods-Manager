import '../../../core/theme/app_theme.dart';
import '../../../core/update/windows_update_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String modsPath;
  final String downloadPath;
  final Future<void> Function(String modsPath, String downloadPath) onChanged;
  const SettingsPage({
    super.key,
    required this.modsPath,
    required this.downloadPath,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String modsPath = widget.modsPath;
  late String downloadPath = widget.downloadPath;
  bool saving = false;
  bool checkingForUpdates = false;

  Future<void> _checkForUpdates() async {
    setState(() => checkingForUpdates = true);
    try {
      await WindowsUpdateService.instance.checkNow();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể kiểm tra bản cập nhật. Hãy thử lại khi có Internet.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => checkingForUpdates = false);
    }
  }

  Future<void> _pickMods() async {
    final path = await getDirectoryPath(confirmButtonText: 'Chọn thư mục Mods');
    if (mounted && !saving && path != null && path != modsPath) {
      await _applyPaths(path, downloadPath);
    }
  }

  Future<void> _pickDownload() async {
    final path = await getDirectoryPath(
      confirmButtonText: 'Chọn thư mục Download',
    );
    if (mounted && !saving && path != null && path != downloadPath) {
      await _applyPaths(modsPath, path);
    }
  }

  Future<void> _applyPaths(String newModsPath, String newDownloadPath) async {
    setState(() => saving = true);
    try {
      await widget.onChanged(newModsPath, newDownloadPath);
      if (mounted) {
        setState(() {
          modsPath = newModsPath;
          downloadPath = newDownloadPath;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu đường dẫn thư mục.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            _FolderSetting(
              title: 'Mods',
              path: modsPath,
              icon: Icons.extension_outlined,
              onChange: saving ? null : _pickMods,
            ),
            const SizedBox(height: 12),
            _FolderSetting(
              title: 'Download',
              path: downloadPath,
              icon: Icons.archive_outlined,
              onChange: saving ? null : _pickDownload,
            ),
            if (WindowsUpdateService.instance.isAvailable) ...[
              const SizedBox(height: 32),
              const Text(
                'Cập nhật ứng dụng',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ứng dụng tự kiểm tra bản mới trên GitHub Releases mỗi ngày.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: checkingForUpdates ? null : _checkForUpdates,
                  icon: const Icon(Icons.system_update_alt),
                  label: Text(
                    checkingForUpdates ? 'Đang kiểm tra…' : 'Kiểm tra cập nhật',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _FolderSetting extends StatelessWidget {
  final String title, path;
  final IconData icon;
  final VoidCallback? onChange;
  const _FolderSetting({
    required this.title,
    required this.path,
    required this.icon,
    required this.onChange,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: onChange, child: const Text('Change')),
      ],
    ),
  );
}
