import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String language;

  SettingsState({required this.themeMode, required this.language});

  SettingsState copyWith({ThemeMode? themeMode, String? language}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return SettingsState(themeMode: ThemeMode.system, language: 'English');
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
