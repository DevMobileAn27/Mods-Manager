import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class LibraryRepository {
  final List<String> characterCatalog;
  final Map<String, List<String>> skinCatalog;
  const LibraryRepository({
    required this.characterCatalog,
    this.skinCatalog = const {},
  });

  Future<void> ensureCharacterFolders(
    String modsPath,
    String downloadPath,
  ) async {
    final roots = [Directory(modsPath), Directory(downloadPath)];
    for (final root in roots) {
      await root.create(recursive: true);
    }

    await _migrateLegacyFolders(roots[0], isDownload: false);
    await _migrateLegacyFolders(roots[1], isDownload: true);
    for (final root in roots) {
      await _migrateSkinPrefixFolders(root);
    }

    // Mỗi skin có một folder ở cả hai tab, kể cả khi chỉ một bên có file.
    final skinNames = <String, String>{};
    for (final root in roots) {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        if (_isLegacyCharacterName(name)) continue;
        skinNames.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    for (final character in characterCatalog) {
      final name = '$character (default)';
      skinNames.putIfAbsent(name.toLowerCase(), () => name);
    }
    for (final entry in skinCatalog.entries) {
      for (final skin in entry.value) {
        final name = '${entry.key} - $skin';
        skinNames.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    for (final root in roots) {
      final existing = <String>{};
      await for (final entity in root.list(followLinks: false)) {
        if (entity is Directory) {
          existing.add(p.basename(entity.path).toLowerCase());
        }
      }
      for (final entry in skinNames.entries) {
        if (!existing.contains(entry.key)) {
          await Directory(p.join(root.path, entry.value)).create();
        }
      }
    }
  }

  Future<List<String>> scanSkinFolders(
    String modsPath,
    String downloadPath,
  ) async {
    final names = <String, String>{};
    for (final rootPath in [modsPath, downloadPath]) {
      try {
        final root = Directory(rootPath);
        if (!await root.exists()) continue;
        final entries = await root
            .list(followLinks: false)
            .toList()
            .timeout(const Duration(seconds: 5));
        for (final entity in entries) {
          if (entity is! Directory) continue;
          final name = p.basename(entity.path);
          if (_isLegacyCharacterName(name)) continue;
          names.putIfAbsent(name.toLowerCase(), () => name);
        }
      } catch (_) {
        // Thư mục mạng không truy cập được không chặn thư mục còn lại.
      }
    }
    return names.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<Directory> skinDirectory(String rootPath, String skinName) async {
    final root = Directory(rootPath);
    if (await root.exists()) {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is Directory &&
            p.basename(entity.path).toLowerCase() == skinName.toLowerCase()) {
          return entity;
        }
      }
    }
    return Directory(p.join(rootPath, skinName));
  }

  Future<void> installZip(File zip, String modsPath, String skinName) async {
    final dest = await skinDirectory(modsPath, skinName);
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final entries = archive.toList();
    final firstSegments = <String>{};
    var canStripRoot = true;
    for (final entry in entries) {
      final parts = entry.name
          .replaceAll('\\', '/')
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;
      firstSegments.add(parts.first);
      if (parts.length < 2 && entry.isFile) canStripRoot = false;
    }
    final commonRoot = canStripRoot && firstSegments.length == 1
        ? firstSegments.first
        : null;

    await dest.create(recursive: true);
    for (final entry in entries) {
      var relative = entry.name.replaceAll('\\', '/');
      if (commonRoot != null && relative.startsWith('$commonRoot/')) {
        relative = relative.substring(commonRoot.length + 1);
      }
      relative = p.normalize(relative);
      if (relative.isEmpty ||
          relative == '.' ||
          p.isAbsolute(relative) ||
          relative == '..' ||
          relative.startsWith('../')) {
        continue;
      }
      final out = p.join(dest.path, relative);
      if (!p.isWithin(dest.path, out)) continue;
      if (entry.isFile) {
        final file = File(out);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content);
      } else {
        await Directory(out).create(recursive: true);
      }
    }
  }

  bool _isLegacyCharacterName(String name) => characterCatalog.any(
    (character) => character.toLowerCase() == name.toLowerCase(),
  );

  String _withoutSkinToken(String name) {
    for (final character in characterCatalog) {
      final prefix = '$character - Skin ';
      if (name.toLowerCase().startsWith(prefix.toLowerCase())) {
        return '$character - ${name.substring(prefix.length)}';
      }
    }
    return name;
  }

  Future<void> _migrateSkinPrefixFolders(Directory root) async {
    final folders = await root.list(followLinks: false).toList();
    for (final entity in folders) {
      if (entity is! Directory) continue;
      final oldName = p.basename(entity.path);
      final newName = _withoutSkinToken(oldName);
      if (newName == oldName) continue;
      final target = await skinDirectory(root.path, newName);
      await _moveWithoutOverwrite(entity, target);
    }
  }

  Future<void> _migrateLegacyFolders(
    Directory root, {
    required bool isDownload,
  }) async {
    final legacyFolders = <Directory>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          _isLegacyCharacterName(p.basename(entity.path))) {
        legacyFolders.add(entity);
      }
    }
    for (final legacy in legacyFolders) {
      final character = p.basename(legacy.path);
      await for (final child in legacy.list(followLinks: false)) {
        final name = p.basename(child.path);
        if (child is Directory) {
          final target = await skinDirectory(
            root.path,
            _withoutSkinToken(name),
          );
          await _moveWithoutOverwrite(child, target);
        } else if (child is File) {
          final stem = p.basenameWithoutExtension(name);
          final isNamedSkin = stem.toLowerCase().startsWith(
            '${character.toLowerCase()} - ',
          );
          final skinName = isDownload && isNamedSkin
              ? _withoutSkinToken(stem)
              : '$character (default)';
          final targetDir = await skinDirectory(root.path, skinName);
          await targetDir.create(recursive: true);
          final target = File(p.join(targetDir.path, name));
          if (!await target.exists()) await child.rename(target.path);
        }
      }
      if (await legacy.list(followLinks: false).isEmpty) {
        await legacy.delete();
      }
    }
  }

  Future<void> _moveWithoutOverwrite(Directory source, Directory target) async {
    if (!await target.exists()) {
      await source.rename(target.path);
      return;
    }
    await for (final child in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(child.path));
      if (child is Directory) {
        await _moveWithoutOverwrite(child, Directory(destination));
      } else if (child is File && !await File(destination).exists()) {
        await child.rename(destination);
      }
    }
    if (await source.list(followLinks: false).isEmpty) await source.delete();
  }
}
