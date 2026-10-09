import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/character_catalog.dart';
import '../core/folder_access.dart';
import '../core/localization/app_language.dart';
import '../core/localization/app_locale_cubit.dart';
import '../core/theme/app_theme.dart';
import '../features/library/data/library_repository.dart';
import '../features/library/presentation/library_page.dart';
import '../features/onboarding/presentation/get_started_page.dart';

class XxmiApp extends StatelessWidget {
  const XxmiApp({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AppLocaleCubit()..load(),
    child: BlocBuilder<AppLocaleCubit, AppLanguage>(
      builder: (context, language) => MaterialApp(
        title: 'Visual Mods Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: language.locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const RootPage(),
      ),
    ),
  );
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  String? mods, download;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SharedPreferences.getInstance();
    final savedMods = s.getString('mods');
    final savedDownload = s.getString('download');
    final restoredMods = await FolderAccess.restoreBookmark(
      s.getString('modsBookmark'),
    );
    final restoredDownload = await FolderAccess.restoreBookmark(
      s.getString('downloadBookmark'),
    );
    // Bản cũ chỉ lưu path, không có quyền sandbox sau khi mở lại.
    final needsReauthorization =
        Platform.isMacOS &&
        ((savedMods != null && restoredMods == null) ||
            (savedDownload != null && restoredDownload == null));
    setState(() {
      mods = needsReauthorization ? null : (restoredMods ?? savedMods);
      download = needsReauthorization
          ? null
          : (restoredDownload ?? savedDownload);
      loading = false;
    });
  }

  Future<void> _persistPaths(String modsPath, String downloadPath) async {
    await _save('mods', modsPath);
    await _save('download', downloadPath);
    final prefs = await SharedPreferences.getInstance();
    final modsBookmark = await FolderAccess.createBookmark(modsPath);
    final downloadBookmark = await FolderAccess.createBookmark(downloadPath);
    if (modsBookmark != null) {
      await prefs.setString('modsBookmark', modsBookmark);
    }
    if (downloadBookmark != null) {
      await prefs.setString('downloadBookmark', downloadBookmark);
    }
  }

  Future<void> _save(String key, String value) async {
    final s = await SharedPreferences.getInstance();
    await s.setString(key, value);
    if (!mounted) return;
    if (key == 'mods') {
      setState(() => mods = value);
    } else {
      setState(() => download = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (mods == null || download == null) {
      return SetupPage(
        onDone: (m, d) async {
          try {
            await const LibraryRepository(
              characterCatalog: zzzCharacterFolders,
              skinCatalog: zzzSkinFolders,
            ).ensureCharacterFolders(m, d).timeout(const Duration(seconds: 8));
          } catch (_) {}
          await _persistPaths(m, d);
        },
      );
    }
    return MainPage(
      modsPath: mods!,
      downloadPath: download!,
      onPathsChanged: _persistPaths,
    );
  }
}
