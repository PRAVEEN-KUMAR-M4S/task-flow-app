import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SecureStorageService _secureStorage;

  ThemeCubit({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage,
        super(ThemeMode.light);

  /// Load persisted theme preference from secure storage.
  Future<void> loadTheme() async {
    final value = await _secureStorage.getThemeMode();
    if (value == 'dark') {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.light);
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
      _secureStorage.setThemeMode(mode: 'dark');
    } else {
      emit(ThemeMode.light);
      _secureStorage.setThemeMode(mode: 'light');
    }
  }

  void setLight() {
    emit(ThemeMode.light);
    _secureStorage.setThemeMode(mode: 'light');
  }

  void setDark() {
    emit(ThemeMode.dark);
    _secureStorage.setThemeMode(mode: 'dark');
  }
}
