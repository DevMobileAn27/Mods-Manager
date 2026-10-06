import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/core/character_catalog.dart';

void main() {
  test('contains the current agents and both protagonists', () {
    expect(zzzCharacterFolders, hasLength(62));
    expect(zzzCharacterFolders, contains('Promeia'));
    expect(zzzCharacterFolders, containsAll(['Belle', 'Wise']));
  });

  test('stores an attribute for every character folder', () {
    for (final character in zzzCharacterFolders) {
      expect(zzzCharacterInfoFor(character), isNotNull, reason: character);
    }
  });

  test('resolves attributes case-insensitively', () {
    expect(zzzCharacterInfoFor('astra yao')?.attribute, ZzzAttribute.ether);
    expect(
      zzzCharacterInfoFor('Roxy Ifrita Pryce')?.attribute,
      ZzzAttribute.wind,
    );
  });

  test('every extra outfit has a local portrait', () {
    final allSkins = <String>{};
    for (final entry in zzzSkinFolders.entries) {
      for (final outfit in entry.value) {
        allSkins.add('${entry.key} - $outfit');
      }
    }
    expect(allSkins, hasLength(29));
    expect(zzzSkinAvatarAssets.keys.toSet(), allSkins);
    for (final asset in zzzSkinAvatarAssets.values) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
    for (final asset in zzzAvatarAssets.values) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });
}
