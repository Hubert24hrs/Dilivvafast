import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light/dark/system preference across launches.
///
/// Defaults to [ThemeMode.system] so a fresh install follows the OS setting,
/// which is what people expect on both iOS and Android.
class ThemeController extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getString(_key));
    } catch (_) {
      // A failed read must never block the app from rendering.
      return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Preference is cosmetic — keep the in-memory choice even if it
      // could not be written.
    }
  }

  /// Cycles system → light → dark → system, for a single-tap toggle.
  Future<void> cycle() {
    final current = state.value ?? ThemeMode.system;
    return setMode(switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// The resolved mode, treating a still-loading preference as `system` so the
/// first frame never flashes the wrong theme.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeControllerProvider).value ?? ThemeMode.system;
});

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  IconData get icon => switch (this) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}
