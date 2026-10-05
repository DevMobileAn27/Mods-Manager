import '../../../core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../../core/character_catalog.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../data/library_repository.dart';
import '../../settings/presentation/settings_page.dart';

class MainPage extends StatelessWidget {
  final String modsPath, downloadPath;
  final Future<void> Function(String modsPath, String downloadPath)
  onPathsChanged;
  const MainPage({
    super.key,
    required this.modsPath,
    required this.downloadPath,
    required this.onPathsChanged,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LibraryBloc(
      repository: LibraryRepository(
        characterCatalog: zzzCharacterFolders,
        skinCatalog: zzzSkinFolders,
      ),
    )..add(LibraryStarted(modsPath: modsPath, downloadPath: downloadPath)),
    child: _LibraryShell(onPathsChanged: onPathsChanged),
  );
}

class _LibraryShell extends StatelessWidget {
  final Future<void> Function(String, String) onPathsChanged;
  const _LibraryShell({required this.onPathsChanged});

  @override
  Widget build(BuildContext context) => BlocBuilder<LibraryBloc, LibraryState>(
    builder: (context, state) {
      final root = state.selectedTab == 0 ? state.modsPath : state.downloadPath;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            LibraryTopBar(state: state, onPathsChanged: onPathsChanged),
            Expanded(
              child: state.selectedCharacter == null
                  ? CharacterGrid(
                      characters: state.characters,
                      loading: state.status == LibraryStatus.loading,
                      onSelect: (name) => context.read<LibraryBloc>().add(
                        LibraryCharacterOpened(name),
                      ),
                    )
                  : DetailView(
                      skinName: state.selectedCharacter!,
                      root: root,
                      isDownload: state.selectedTab == 1,
                      modsRoot: state.modsPath,
                      onBack: () => context.read<LibraryBloc>().add(
                        const LibraryCharacterClosed(),
                      ),
                      onRefresh: () => context.read<LibraryBloc>().add(
                        const LibraryRefreshed(),
                      ),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class LibraryTopBar extends StatelessWidget {
  final LibraryState state;
  final Future<void> Function(String, String) onPathsChanged;
  const LibraryTopBar({
    super.key,
    required this.state,
    required this.onPathsChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.tabTrack,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tab(context, 0, Icons.extension_outlined, 'Mods'),
              _tab(context, 1, Icons.archive_outlined, 'Download'),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: () =>
              context.read<LibraryBloc>().add(const LibraryRefreshed()),
          icon: const Icon(Icons.refresh, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Settings',
          onPressed: () async {
            final bloc = context.read<LibraryBloc>();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  modsPath: state.modsPath,
                  downloadPath: state.downloadPath,
                  onSaved: (mods, download) async {
                    await onPathsChanged(mods, download);
                    bloc.add(
                      LibraryStarted(modsPath: mods, downloadPath: download),
                    );
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
        ),
      ],
    ),
  );

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final active = state.selectedTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.read<LibraryBloc>().add(LibraryTabChanged(index)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 116),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? AppColors.surface : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterGrid extends StatelessWidget {
  final List<String> characters;
  final bool loading;
  final ValueChanged<String> onSelect;
  const CharacterGrid({
    super.key,
    required this.characters,
    required this.loading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        const horizontalPadding = 28.0;
        final count = (box.maxWidth / 230).floor().clamp(2, 6);
        final cardWidth =
            (box.maxWidth - horizontalPadding * 2 - gap * (count - 1)) / count;
        final avatarSize = cardWidth < 190 ? 100.0 : 125.0;
        final cardHeight = avatarSize * 1.15 + 80;
        final groups = <String, List<String>>{};
        for (final skinName in characters) {
          groups
              .putIfAbsent(_characterForSkin(skinName), () => [])
              .add(skinName);
        }
        final groupWidgets = <Widget>[];
        for (final skins in groups.values) {
          for (var start = 0; start < skins.length; start += count) {
            final batch = skins.skip(start).take(count).toList();
            groupWidgets.add(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < batch.length; index++) ...[
                    if (index > 0) const SizedBox(width: gap),
                    _skinCard(batch[index], cardWidth, cardHeight, avatarSize),
                  ],
                ],
              ),
            );
          }
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Wrap(spacing: gap, runSpacing: gap, children: groupWidgets),
        );
      },
    );
  }

  Widget _skinCard(
    String skinName,
    double width,
    double height,
    double avatarSize,
  ) => SizedBox(
    width: width,
    height: height,
    child: Tooltip(
      message: skinName,
      child: InkWell(
        onTap: () => onSelect(skinName),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              children: [
                HeroAvatar(
                  name: _characterForSkin(skinName),
                  size: avatarSize,
                  assetPath: _skinAssetFor(skinName),
                ),
                const SizedBox(height: 10),
                Text(
                  _displaySkinName(skinName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class HeroAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? assetPath;
  const HeroAvatar({
    super.key,
    required this.name,
    required this.size,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final hue = (name.codeUnitAt(0) * 37) % 360;
    final asset = assetPath ?? zzzAvatarAssets[name];
    final width = size * .78;
    final height = size * 1.15;
    final fallback = Text(
      name
          .trim()
          .split(RegExp(r'\s+'))
          .map((x) => x.isEmpty ? '' : x[0])
          .take(2)
          .join()
          .toUpperCase(),
      style: TextStyle(
        fontSize: size * .27,
        fontWeight: FontWeight.w700,
        color: HSVColor.fromAHSV(1, hue.toDouble(), .65, .3).toColor(),
      ),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HSVColor.fromAHSV(1, hue.toDouble(), .28, .95).toColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(child: fallback)
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: fallback),
            ),
    );
  }
}

String _characterForSkin(String skinName) {
  final lower = skinName.toLowerCase();
  final characters = [...zzzCharacterFolders]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final character in characters) {
    final prefix = character.toLowerCase();
    if (lower == '$prefix (default)' || lower.startsWith('$prefix - ')) {
      return character;
    }
  }
  return skinName;
}

String _displaySkinName(String skinName) {
  final character = _characterForSkin(skinName);
  return skinName.toLowerCase() == '${character.toLowerCase()} (default)'
      ? character
      : skinName;
}

String? _skinAssetFor(String skinName) {
  for (final entry in zzzSkinAvatarAssets.entries) {
    if (entry.key.toLowerCase() == skinName.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

class DetailView extends StatefulWidget {
  final String skinName, root, modsRoot;
  final bool isDownload;
  final VoidCallback onBack, onRefresh;
  const DetailView({
    super.key,
    required this.skinName,
    required this.root,
    required this.modsRoot,
    required this.isDownload,
    required this.onBack,
    required this.onRefresh,
  });
  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  List<FileSystemEntity> entries = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final dir = await context.read<LibraryBloc>().repository.skinDirectory(
      widget.root,
      widget.skinName,
    );
    entries = [];
    if (await dir.exists()) {
      entries = await dir.list(followLinks: false).toList();
      entries.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> delete(FileSystemEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xoá mục này?'),
        content: Text(p.basename(e.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (e is Directory) {
      await e.delete(recursive: true);
    } else {
      await e.delete();
    }
    await load();
    widget.onRefresh();
  }

  Future<void> useZip(File zip) async {
    await context.read<LibraryBloc>().repository.installZip(
      zip,
      widget.modsRoot,
      widget.skinName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cài skin vào Mods/${widget.skinName}')),
      );
    }
    widget.onRefresh();
  }

  void menu(Offset pos, FileSystemEntity e) async {
    final isZip =
        widget.isDownload &&
        e is File &&
        p.extension(e.path).toLowerCase() == '.zip';
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      items: [
        if (isZip)
          const PopupMenuItem(
            value: 'use',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline),
              title: Text('Dùng skin này'),
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Xoá'),
          ),
        ),
      ],
    );
    if (action == 'delete') delete(e);
    if (action == 'use') useZip(e as File);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              HeroAvatar(
                name: _characterForSkin(widget.skinName),
                size: 40,
                assetPath: _skinAssetFor(widget.skinName),
              ),
              const SizedBox(width: 12),
              Text(
                _displaySkinName(widget.skinName),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
              ? const Center(child: Text('Thư mục này đang trống.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(28),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final e = entries[i],
                        isDir = e is Directory,
                        isZip =
                            !isDir &&
                            p.extension(e.path).toLowerCase() == '.zip';
                    return GestureDetector(
                      onSecondaryTapDown: (d) => menu(d.globalPosition, e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDir
                                  ? Icons.folder_outlined
                                  : isZip
                                  ? Icons.archive_outlined
                                  : Icons.insert_drive_file_outlined,
                              color: isDir
                                  ? AppColors.archive
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                p.basename(e.path),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isZip && widget.isDownload)
                              const Chip(
                                label: Text(
                                  'ZIP',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
