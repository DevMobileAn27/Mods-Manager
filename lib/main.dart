import 'dart:async';

import 'package:flutter/material.dart';
import 'app/xxmi_app.dart';
import 'core/update/windows_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XxmiApp());
  unawaited(WindowsUpdateService.instance.checkInBackground());
}
