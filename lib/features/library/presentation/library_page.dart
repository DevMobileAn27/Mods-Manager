import '../../../core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'animated_search_field.dart';
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

class _LibraryShell extends StatefulWidget {
  final Future<void> Function(String, String) onPathsChanged;
  const _LibraryShell({required this.onPathsChanged});

  @override
  State<_LibraryShell> createState() => _LibraryShellState();
}

class _LibraryShellState extends State<_LibraryShell> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) => BlocBuilder<LibraryBloc, LibraryState>(
    builder: (context, state) {
      final root = state.selectedTab == 0 ? state.modsPath : state.downloadPath;
      final query = searchQuery.trim().toLowerCase();
      final visibleCharacters = query.isEmpty
          ? state.characters
          : state.characters
                .where(
                  (name) =>
                      _displaySkinName(name).toLowerCase().contains(query),
                )
                .toList();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            LibraryTopBar(
              state: state,
              onPathsChanged: widget.onPathsChanged,
              onSearchChanged: (value) => setState(() => searchQuery = value),
            ),
            Expanded(
              child: state.selectedCharacter == null
                  ? CharacterGrid(
                      // Keep a separate scroll position for each library tab
                      // when the grid is temporarily replaced by DetailView.
                      key: ValueKey(state.selectedTab),
                      scrollStorageKey: 'library-tab-${state.selectedTab}',
                      characters: visibleCharacters,
                      zipCounts: state.zipCounts,
                      folderCounts: state.modFolderCounts,
                      showFolderStatus: state.selectedTab == 0,
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
  final ValueChanged<String> onSearchChanged;
  const LibraryTopBar({
    super.key,
    required this.state,
    required this.onPathsChanged,
    required this.onSearchChanged,
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
        AnimatedSearchField(onChanged: onSearchChanged),
        const SizedBox(width: 10),
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
                  onChanged: (mods, download) async {
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
  final Map<String, int> zipCounts;
  final Map<String, int> folderCounts;
  final bool loading;
  final ValueChanged<String> onSelect;
  final String scrollStorageKey;
  final bool showFolderStatus;
  const CharacterGrid({
    super.key,
    required this.characters,
    required this.zipCounts,
    this.folderCounts = const {},
    required this.loading,
    required this.onSelect,
    this.scrollStorageKey = 'default',
    this.showFolderStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (characters.isEmpty) {
      return const Center(child: Text('Không tìm thấy nhân vật hoặc skin.'));
    }
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        const horizontalPadding = 28.0;
        final count = (box.maxWidth / 230).floor().clamp(2, 6);
        final cardWidth =
            (box.maxWidth - horizontalPadding * 2 - gap * (count - 1)) / count;
        final baseAvatarSize = cardWidth < 190 ? 100.0 : 125.0;
        final avatarSize = baseAvatarSize * 1.5;
        final cardHeight = avatarSize * 1.15 + 80;
        final groups = <String, List<String>>{};
        for (final skinName in characters) {
          groups
              .putIfAbsent(_characterForSkin(skinName), () => [])
              .add(skinName);
        }
        final orderedSkins = groups.values.expand((skins) => skins).toList();
        return GridView.builder(
          key: PageStorageKey<String>('character-grid-$scrollStorageKey'),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: orderedSkins.length,
          itemBuilder: (context, index) => _skinCard(
            orderedSkins[index],
            cardWidth,
            cardHeight,
            avatarSize,
            zipCounts[orderedSkins[index].toLowerCase()] ?? 0,
            folderCounts[orderedSkins[index].toLowerCase()] ?? 0,
          ),
        );
      },
    );
  }

  Widget _skinCard(
    String skinName,
    double width,
    double height,
    double avatarSize,
    int zipCount,
    int folderCount,
  ) => SizedBox(
    width: width,
    height: height,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  HeroAvatar(
                    name: _characterForSkin(skinName),
                    size: avatarSize,
                    assetPath: _skinAssetFor(skinName),
                  ),
                  if (showFolderStatus && folderCount > 0)
                    _FolderStatusBadge(isValid: folderCount == 1)
                  else if (!showFolderStatus && zipCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$zipCount',
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
  );
}

class _FolderStatusBadge extends StatelessWidget {
  final bool isValid;

  const _FolderStatusBadge({required this.isValid});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 10,
    right: 10,
    child: Tooltip(
      message: isValid
          ? 'Hợp lệ: có 1 thư mục mod'
          : 'Không hợp lệ: có từ 2 thư mục mod',
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.5),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isValid ? Icons.check : Icons.close,
          size: 18,
          color: isValid ? AppColors.success : AppColors.danger,
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
    final attribute = zzzCharacterInfoFor(name)?.attribute;
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
        color:
            _attributeBackground(attribute) ??
            HSVColor.fromAHSV(1, hue.toDouble(), .28, .95).toColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(child: fallback)
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: fallback),
            ),
    );
  }
}

Color? _attributeBackground(ZzzAttribute? attribute) => switch (attribute) {
  ZzzAttribute.physical => const Color(0xffe9c77b),
  ZzzAttribute.fire => const Color(0xfff2a36f),
  ZzzAttribute.ice => const Color(0xff9cd9ea),
  ZzzAttribute.electric => const Color(0xffb8a4e8),
  ZzzAttribute.ether => const Color(0xffc99be6),
  ZzzAttribute.wind => const Color(0xffa8d9b0),
  ZzzAttribute.frost => const Color(0xff91c9d6),
  ZzzAttribute.lumiflux => const Color(0xfff2d58a),
  ZzzAttribute.honedEdge => const Color(0xffd7dce3),
  ZzzAttribute.auricInk => const Color(0xffe3bd72),
  null => null,
};

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
      entries = (await dir.list(followLinks: false).toList())
          .where((entry) => !_isHiddenFileSystemEntry(entry))
          .toList();
      entries.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  bool _isHiddenFileSystemEntry(FileSystemEntity entry) {
    final name = p.basename(entry.path).toLowerCase();
    return name.startsWith('.') || name == 'thumbs.db' || name == 'desktop.ini';
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

  Future<void> useArchive(File archive) async {
    try {
      final installedFolder = await context
          .read<LibraryBloc>()
          .repository
          .installArchive(archive, widget.modsRoot, widget.skinName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cài skin vào Mods/${widget.skinName}/$installedFolder',
            ),
          ),
        );
      }
      widget.onRefresh();
    } on FileSystemException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể giải nén ${p.basename(archive.path)}. Hãy kiểm tra file hoặc cài 7-Zip.',
            ),
          ),
        );
      }
    }
  }

  Future<void> openFolder() async {
    final directory = await context
        .read<LibraryBloc>()
        .repository
        .skinDirectory(widget.root, widget.skinName);
    if (!await directory.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thư mục skin.')),
        );
      }
      return;
    }

    final command = Platform.isWindows
        ? ('explorer.exe', <String>[directory.path])
        : Platform.isMacOS
        ? ('open', <String>[directory.path])
        : ('xdg-open', <String>[directory.path]);
    try {
      await Process.start(
        command.$1,
        command.$2,
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở thư mục trong trình quản lý file.'),
          ),
        );
      }
    }
  }

  void menu(Offset pos, FileSystemEntity e) async {
    final isArchive =
        widget.isDownload &&
        e is File &&
        {'.zip', '.rar'}.contains(p.extension(e.path).toLowerCase());
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      menuPadding: EdgeInsets.zero,
      items: [
        if (isArchive)
          const PopupMenuItem(
            value: 'use',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
              ),
              title: Text('Dùng trang phục này'),
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text('Xoá'),
          ),
        ),
      ],
    );
    if (action == 'delete') delete(e);
    if (action == 'use') useArchive(e as File);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 14, 22, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _displaySkinName(widget.skinName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mở trong thư mục',
                onPressed: openFolder,
                icon: const Icon(Icons.folder_open_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
              ? const Center(child: Text('Thư mục này đang trống.'))
              : FileEntryGrid(entries: entries, onContextMenu: menu),
        ),
      ],
    );
  }
}

class FileEntryGrid extends StatelessWidget {
  final List<FileSystemEntity> entries;
  final void Function(Offset position, FileSystemEntity entry) onContextMenu;

  const FileEntryGrid({
    super.key,
    required this.entries,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(28),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      mainAxisExtent: 170,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
    ),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final isDirectory = entry is Directory;
      final isArchive =
          !isDirectory &&
          {'.zip', '.rar'}.contains(p.extension(entry.path).toLowerCase());
      final icon = isDirectory
          ? Icons.folder_outlined
          : isArchive
          ? Icons.archive_outlined
          : Icons.insert_drive_file_outlined;
      final color = isDirectory ? AppColors.archive : AppColors.primary;
      final iconBackground = isDirectory
          ? AppColors.archive.withValues(alpha: 0.12)
          : AppColors.primarySoft;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) =>
            onContextMenu(details.globalPosition, entry),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                p.basename(entry.path),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
