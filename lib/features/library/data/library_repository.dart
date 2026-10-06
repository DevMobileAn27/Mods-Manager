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

    // Chỉ đồng bộ các skin thuộc catalog sang cả hai root. Các folder lạ
    // vẫn được hiển thị ở root đang chứa dữ liệu nhưng không được tự tạo lại
    // ở root còn lại sau khi người dùng đã xoá chúng.
    final catalogSkinNames = <String, String>{};
    for (final root in roots) {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        if (_isCatalogSkinName(name)) {
          catalogSkinNames.putIfAbsent(name.toLowerCase(), () => name);
        }
      }
    }
    for (final character in characterCatalog) {
      final name = '$character (default)';
      catalogSkinNames.putIfAbsent(name.toLowerCase(), () => name);
    }
    for (final entry in skinCatalog.entries) {
      for (final skin in entry.value) {
        final name = '${entry.key} - $skin';
        catalogSkinNames.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    for (final root in roots) {
      final existing = <String>{};
      await for (final entity in root.list(followLinks: false)) {
        if (entity is Directory) {
          existing.add(p.basename(entity.path).toLowerCase());
        }
      }
      for (final entry in catalogSkinNames.entries) {
        if (!existing.contains(entry.key)) {
          await Directory(p.join(root.path, entry.value)).create();
        }
      }
    }
  }

  Future<List<String>> scanSkinFolders(String modsPath, String downloadPath) =>
      _scanSkinFolders([modsPath, downloadPath]);

  /// Scans only the root shown by the active library tab.
  ///
  /// The two-root scan above is kept for migration/tests, while the UI uses
  /// this method so a folder that exists only in Download cannot remain
  /// visible in the Mods tab (or vice versa).
  Future<List<String>> scanSkinFoldersAt(String rootPath) =>
      _scanSkinFolders([rootPath]);

  Future<List<String>> _scanSkinFolders(List<String> rootPaths) async {
    final names = <String, String>{};
    for (final rootPath in rootPaths) {
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
          if (!await _shouldIncludeSkinFolder(entity)) continue;
          names.putIfAbsent(name.toLowerCase(), () => name);
        }
      } catch (_) {
        // Thư mục mạng không truy cập được không chặn thư mục còn lại.
      }
    }
    return names.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<Map<String, int>> scanZipCounts(String rootPath) async {
    final counts = <String, int>{};
    final root = Directory(rootPath);
    if (!await root.exists()) return counts;
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        var count = 0;
        await for (final child in entity.list(followLinks: false)) {
          final name = p.basename(child.path);
          if (child is File &&
              !name.startsWith('.') &&
              p.extension(name).toLowerCase() == '.zip') {
            count++;
          }
        }
        if (count > 0) {
          counts[p.basename(entity.path).toLowerCase()] = count;
        }
      }
    } catch (_) {
      // A folder that cannot be read should not block the rest of the grid.
    }
    return counts;
  }

  Future<Map<String, int>> scanChildFolderCounts(String rootPath) async {
    final counts = <String, int>{};
    final root = Directory(rootPath);
    if (!await root.exists()) return counts;
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        var count = 0;
        await for (final child in entity.list(followLinks: false)) {
          if (child is! Directory) continue;
          final name = p.basename(child.path).toLowerCase();
          if (name.startsWith('.') ||
              name == 'thumbs.db' ||
              name == 'desktop.ini') {
            continue;
          }
          count++;
        }
        if (count > 0) {
          counts[p.basename(entity.path).toLowerCase()] = count;
        }
      }
    } catch (_) {
      // A folder that cannot be read should not block the rest of the grid.
    }
    return counts;
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

  Future<String> installZip(File zip, String modsPath, String skinName) =>
      installArchive(zip, modsPath, skinName);

  Future<String> installArchive(
    File archiveFile,
    String modsPath,
    String skinName,
  ) async {
    final extension = p.extension(archiveFile.path).toLowerCase();
    if (extension != '.zip' && extension != '.rar') {
      throw UnsupportedError('Chỉ hỗ trợ file ZIP và RAR.');
    }

    final dest = await skinDirectory(modsPath, skinName);
    final folderName = _datedInstallFolderName(skinName, DateTime.now());
    final stagingRoot = await Directory.systemTemp.createTemp(
      'visual-mods-install-',
    );
    final staging = Directory(p.join(stagingRoot.path, folderName));
    await staging.create(recursive: true);

    try {
      if (extension == '.zip') {
        final archive = ZipDecoder().decodeBytes(
          await archiveFile.readAsBytes(),
        );
        await _stageZipArchive(archive, staging);
      } else {
        final extracted = Directory(p.join(stagingRoot.path, 'rar'));
        await extracted.create();
        await _extractRarArchive(archiveFile, extracted);
        await _stageExtractedArchive(extracted, staging);
      }

      await dest.create(recursive: true);
      final target = await _nextAvailableDirectory(dest, folderName);
      await _moveDirectory(staging, target);
      return p.basename(target.path);
    } finally {
      if (await stagingRoot.exists()) {
        await stagingRoot.delete(recursive: true);
      }
    }
  }

  Future<void> _stageZipArchive(Archive archive, Directory staging) async {
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

    for (final entry in entries) {
      var relative = entry.name.replaceAll('\\', '/');
      if (commonRoot != null && relative.startsWith('$commonRoot/')) {
        relative = relative.substring(commonRoot.length + 1);
      }
      relative = p.normalize(relative);
      if (!_isSafeArchivePath(relative)) continue;
      final out = p.join(staging.path, relative);
      if (!p.isWithin(staging.path, out)) continue;
      if (entry.isFile) {
        final file = File(out);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content);
      } else {
        await Directory(out).create(recursive: true);
      }
    }
  }

  Future<void> _stageExtractedArchive(
    Directory extracted,
    Directory staging,
  ) async {
    final entries = await extracted
        .list(recursive: true, followLinks: false)
        .toList();
    final relativePaths = <FileSystemEntity, String>{};
    final firstSegments = <String>{};
    var canStripRoot = true;

    for (final entry in entries) {
      if (entry is! File && entry is! Directory) continue;
      final relative = p
          .relative(entry.path, from: extracted.path)
          .replaceAll('\\', '/');
      final parts = relative
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;
      relativePaths[entry] = relative;
      firstSegments.add(parts.first);
      if (parts.length < 2 && entry is File) canStripRoot = false;
    }

    final commonRoot = canStripRoot && firstSegments.length == 1
        ? firstSegments.first
        : null;
    for (final entry in entries) {
      final original = relativePaths[entry];
      if (original == null) continue;
      var relative = original;
      if (commonRoot != null && relative.startsWith('$commonRoot/')) {
        relative = relative.substring(commonRoot.length + 1);
      }
      relative = p.normalize(relative);
      if (!_isSafeArchivePath(relative)) continue;
      final out = p.join(staging.path, relative);
      if (!p.isWithin(staging.path, out)) continue;
      if (entry is Directory) {
        await Directory(out).create(recursive: true);
      } else if (entry is File) {
        await entry.copy(out);
      }
    }
  }

  bool _isSafeArchivePath(String path) =>
      path.isNotEmpty &&
      path != '.' &&
      !p.isAbsolute(path) &&
      path != '..' &&
      !path.startsWith('../');

  Future<void> _extractRarArchive(File archiveFile, Directory output) async {
    final outputPath = output.path;
    final commands = <(String, List<String>)>[
      ('tar.exe', ['-xf', archiveFile.path, '-C', outputPath]),
      ('7z.exe', ['x', archiveFile.path, '-o$outputPath', '-y']),
      ('7za.exe', ['x', archiveFile.path, '-o$outputPath', '-y']),
      ('UnRAR.exe', ['x', '-o+', archiveFile.path, outputPath]),
    ];
    final errors = <String>[];
    for (final command in commands) {
      try {
        final result = await Process.run(command.$1, command.$2);
        if (result.exitCode == 0) return;
        final details = result.stderr.toString().trim();
        errors.add(
          '${command.$1} exited with ${result.exitCode}${details.isEmpty ? '' : ': $details'}',
        );
      } on ProcessException catch (error) {
        errors.add('${command.$1}: ${error.message}');
      }
    }
    throw FileSystemException(
      'Không thể giải nén file RAR. Hãy cập nhật Windows hoặc cài 7-Zip.\n'
      '${errors.join('\n')}',
      archiveFile.path,
    );
  }

  String _datedInstallFolderName(String skinName, DateTime date) {
    var character = skinName;
    for (final candidate in characterCatalog) {
      final lowerSkin = skinName.toLowerCase();
      final lowerCandidate = candidate.toLowerCase();
      if (lowerSkin == '$lowerCandidate (default)' ||
          lowerSkin.startsWith('$lowerCandidate - ')) {
        character = candidate;
        break;
      }
    }
    final safeCharacter = character
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return [safeCharacter, day, month, year].join('_');
  }

  Future<Directory> _nextAvailableDirectory(
    Directory parent,
    String baseName,
  ) async {
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? baseName : '${baseName}_$suffix';
      final candidate = Directory(p.join(parent.path, name));
      if (!await candidate.exists()) return candidate;
      suffix++;
    }
  }

  Future<void> _moveDirectory(Directory source, Directory target) async {
    await target.parent.create(recursive: true);
    try {
      await source.rename(target.path);
    } on FileSystemException {
      await _copyDirectory(source, target);
      await source.delete(recursive: true);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }

  bool _isLegacyCharacterName(String name) => characterCatalog.any(
    (character) => character.toLowerCase() == name.toLowerCase(),
  );

  bool _isCatalogSkinName(String name) {
    if (_isLegacyCharacterName(name)) return false;
    final lowerName = name.toLowerCase();
    for (final character in characterCatalog) {
      final lowerCharacter = character.toLowerCase();
      if (lowerName == '$lowerCharacter (default)' ||
          lowerName.startsWith('$lowerCharacter - ')) {
        return true;
      }
    }
    for (final entry in skinCatalog.entries) {
      for (final skin in entry.value) {
        if (lowerName == '${entry.key} - $skin'.toLowerCase()) return true;
      }
    }
    return false;
  }

  Future<bool> _shouldIncludeSkinFolder(Directory directory) async {
    final name = p.basename(directory.path);
    if (_isLegacyCharacterName(name)) return false;

    if (_isCatalogSkinName(name)) return true;

    // Old mod folders may remain after their contents are moved into a skin.
    // Keep them on disk, but only show unrelated folders that still hold data.
    try {
      await for (final child in directory.list(followLinks: false)) {
        final childName = p.basename(child.path).toLowerCase();
        if (!childName.startsWith('.') &&
            childName != 'thumbs.db' &&
            childName != 'desktop.ini') {
          return true;
        }
      }
      return false;
    } on FileSystemException {
      // If the folder cannot be read, keep it visible rather than hide data.
      return true;
    }
  }

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
