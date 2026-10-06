import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xxmi_manager/features/library/data/library_repository.dart';

void main() {
  late Directory sandbox;
  late String modsPath;
  late String downloadPath;
  const repository = LibraryRepository(characterCatalog: ['A']);

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('xxmi-library-test-');
    modsPath = p.join(sandbox.path, 'Mods');
    downloadPath = p.join(sandbox.path, 'ZZZ_Download');
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test(
    'creates one default skin folder in each root and syncs added skins',
    () async {
      await Directory(p.join(downloadPath, 'A - ABC')).create(recursive: true);

      await repository.ensureCharacterFolders(modsPath, downloadPath);

      expect(await Directory(p.join(modsPath, 'A (default)')).exists(), isTrue);
      expect(
        await Directory(p.join(downloadPath, 'A (default)')).exists(),
        isTrue,
      );
      expect(await Directory(p.join(modsPath, 'A - ABC')).exists(), isTrue);
      expect(await repository.scanSkinFolders(modsPath, downloadPath), [
        'A (default)',
        'A - ABC',
      ]);
      expect(await Directory(p.join(modsPath, 'A')).exists(), isFalse);
      expect(await Directory(p.join(downloadPath, 'A')).exists(), isFalse);
    },
  );

  test('prepares Astra Yao default and Chandelier folders', () async {
    const astraRepository = LibraryRepository(
      characterCatalog: ['Astra Yao'],
      skinCatalog: {
        'Astra Yao': ['Chandelier'],
      },
    );

    await astraRepository.ensureCharacterFolders(modsPath, downloadPath);

    expect(await astraRepository.scanSkinFolders(modsPath, downloadPath), [
      'Astra Yao (default)',
      'Astra Yao - Chandelier',
    ]);
    for (final root in [modsPath, downloadPath]) {
      expect(
        await Directory(p.join(root, 'Astra Yao (default)')).exists(),
        isTrue,
      );
      expect(
        await Directory(p.join(root, 'Astra Yao - Chandelier')).exists(),
        isTrue,
      );
    }
  });

  test('scans each library tab from its own root', () async {
    await Directory(p.join(modsPath, 'Mods only')).create(recursive: true);
    await File(p.join(modsPath, 'Mods only', 'mod.ini')).writeAsString('data');
    await Directory(
      p.join(downloadPath, 'Download only'),
    ).create(recursive: true);
    await File(
      p.join(downloadPath, 'Download only', 'skin.zip'),
    ).writeAsString('data');

    expect(await repository.scanSkinFoldersAt(modsPath), ['Mods only']);
    expect(await repository.scanSkinFoldersAt(downloadPath), ['Download only']);
  });

  test('hides empty old root folders without deleting them', () async {
    final oldModsFolder = Directory(p.join(modsPath, 'active sport skin'));
    final oldDownloadFolder = Directory(
      p.join(downloadPath, 'alice__bottom_heavy_nsfw__eea05'),
    );
    await oldModsFolder.create(recursive: true);
    await oldDownloadFolder.create(recursive: true);
    await File(p.join(oldModsFolder.path, 'desktop.ini')).writeAsString('');
    await File(p.join(oldDownloadFolder.path, '.DS_Store')).writeAsString('');
    await Directory(p.join(modsPath, 'A - ABC')).create(recursive: true);

    await repository.ensureCharacterFolders(modsPath, downloadPath);

    expect(await repository.scanSkinFolders(modsPath, downloadPath), [
      'A (default)',
      'A - ABC',
    ]);
    expect(await oldModsFolder.exists(), isTrue);
    expect(await oldDownloadFolder.exists(), isTrue);
    expect(
      await Directory(p.join(downloadPath, 'active sport skin')).exists(),
      isFalse,
    );
    expect(
      await Directory(
        p.join(modsPath, 'alice__bottom_heavy_nsfw__eea05'),
      ).exists(),
      isFalse,
    );
  });

  test(
    'keeps unrelated folders visible while they still contain files',
    () async {
      final oldFolder = Directory(p.join(modsPath, 'unidentified mod'));
      await oldFolder.create(recursive: true);
      await File(p.join(oldFolder.path, 'config.ini')).writeAsString('data');

      await repository.ensureCharacterFolders(modsPath, downloadPath);

      expect(await repository.scanSkinFolders(modsPath, downloadPath), [
        'A (default)',
        'unidentified mod',
      ]);
      expect(
        await Directory(p.join(downloadPath, 'unidentified mod')).exists(),
        isFalse,
      );
    },
  );

  test('does not recreate a deleted unrelated folder on refresh', () async {
    final oldFolder = Directory(p.join(modsPath, 'active sport skin'));
    await oldFolder.create(recursive: true);
    await File(p.join(oldFolder.path, 'mod.ini')).writeAsString('data');

    await repository.ensureCharacterFolders(modsPath, downloadPath);
    expect(
      await Directory(p.join(downloadPath, 'active sport skin')).exists(),
      isFalse,
    );

    await oldFolder.delete(recursive: true);
    await repository.ensureCharacterFolders(modsPath, downloadPath);

    expect(await oldFolder.exists(), isFalse);
    expect(
      await Directory(p.join(downloadPath, 'active sport skin')).exists(),
      isFalse,
    );
    expect(
      await repository.scanSkinFoldersAt(modsPath),
      isNot(contains('active sport skin')),
    );
  });

  test('installs A.zip into the skin folder that contains it', () async {
    final zipDir = Directory(p.join(downloadPath, 'A - ABC'));
    await zipDir.create(recursive: true);
    final zip = File(p.join(zipDir.path, 'A.zip'));
    final contents = utf8.encode('skin data');
    final archive = Archive()
      ..addFile(ArchiveFile('pack/config.ini', contents.length, contents));
    await zip.writeAsBytes(ZipEncoder().encode(archive));

    await repository.ensureCharacterFolders(modsPath, downloadPath);
    final installedFolder = await repository.installZip(
      zip,
      modsPath,
      'A - ABC',
    );

    expect(
      await File(
        p.join(modsPath, 'A - ABC', installedFolder, 'config.ini'),
      ).readAsString(),
      'skin data',
    );
    expect(installedFolder, matches(RegExp(r'^A_\d{2}_\d{2}_\d{2}(?:_\d+)?$')));
    expect(
      await File(p.join(modsPath, 'A (default)', 'config.ini')).exists(),
      isFalse,
    );
  });

  test('migrates folders and ZIPs from the old character layout', () async {
    final oldMods = Directory(p.join(modsPath, 'A', 'A - Skin ABC'));
    await oldMods.create(recursive: true);
    await File(p.join(oldMods.path, 'config.ini')).writeAsString('old mod');
    final oldDownload = Directory(p.join(downloadPath, 'A'));
    await oldDownload.create(recursive: true);
    await File(
      p.join(oldDownload.path, 'A - Skin ABC.zip'),
    ).writeAsString('zip');

    await repository.ensureCharacterFolders(modsPath, downloadPath);

    expect(
      await File(p.join(modsPath, 'A - ABC', 'config.ini')).readAsString(),
      'old mod',
    );
    expect(
      await File(p.join(downloadPath, 'A - ABC', 'A - Skin ABC.zip')).exists(),
      isTrue,
    );
    expect(await Directory(p.join(modsPath, 'A')).exists(), isFalse);
    expect(await Directory(p.join(downloadPath, 'A')).exists(), isFalse);
  });

  test('renames root skin folders without losing their files', () async {
    final oldFolder = Directory(p.join(downloadPath, 'A - Skin ABC'));
    await oldFolder.create(recursive: true);
    await File(p.join(oldFolder.path, 'A.zip')).writeAsString('download');

    await repository.ensureCharacterFolders(modsPath, downloadPath);

    expect(await oldFolder.exists(), isFalse);
    expect(
      await File(p.join(downloadPath, 'A - ABC', 'A.zip')).readAsString(),
      'download',
    );
    expect(await Directory(p.join(modsPath, 'A - ABC')).exists(), isTrue);
  });
}
