import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

class AppLocaleCubit extends Cubit<AppLanguage> {
  static const preferenceKey = 'appLanguage';
  bool _changedByUser = false;

  AppLocaleCubit() : super(AppLanguage.vietnamese);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!isClosed && !_changedByUser) {
        emit(AppLanguage.fromCode(preferences.getString(preferenceKey)));
      }
    } catch (_) {
      // Use Vietnamese if stored preferences cannot be read.
    }
  }

  Future<void> changeLanguage(AppLanguage language) async {
    if (language == state) return;
    _changedByUser = true;
    final previous = state;
    emit(language);
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(preferenceKey, language.code)) {
        throw StateError('Unable to save app language');
      }
    } catch (_) {
      if (!isClosed && state == language) emit(previous);
      rethrow;
    }
  }
}
