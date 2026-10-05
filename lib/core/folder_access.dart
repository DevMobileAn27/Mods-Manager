import 'dart:io';
import 'package:flutter/services.dart';

class FolderAccess {
  static const _channel = MethodChannel('xxmi_manager/security_scope');

  static Future<String?> createBookmark(String path) async {
    if (!Platform.isMacOS) return null;
    try {
      return await _channel.invokeMethod<String>('createBookmark', {
        'path': path,
      });
    } catch (_) {
      return null;
    }
  }

  static Future<String?> restoreBookmark(String? encoded) async {
    if (!Platform.isMacOS || encoded == null || encoded.isEmpty) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'restoreBookmark',
        {'bookmark': encoded},
      );
      return result?['path'] as String?;
    } catch (_) {
      return null;
    }
  }
}
