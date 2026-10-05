import 'dart:io';

import 'package:auto_updater/auto_updater.dart';

/// WinSparkle reads this feed from the newest GitHub Release on Windows.
class WindowsUpdateService {
  WindowsUpdateService._();

  static final instance = WindowsUpdateService._();
  static const feedUrl =
      'https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast.xml';

  bool get isAvailable => Platform.isWindows;
  Future<void>? _ready;

  Future<void> _ensureReady() => _ready ??= _configure();

  Future<void> _configure() async {
    await autoUpdater.setFeedURL(feedUrl);
    await autoUpdater.setScheduledCheckInterval(86400);
  }

  Future<void> checkInBackground() async {
    if (!isAvailable) return;
    try {
      await _ensureReady();
      await autoUpdater.checkForUpdates(inBackground: true);
    } catch (_) {
      // A temporary network failure must not prevent the app from opening.
      _ready = null;
    }
  }

  Future<void> checkNow() async {
    if (!isAvailable) return;
    try {
      await _ensureReady();
      await autoUpdater.checkForUpdates();
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }
}
