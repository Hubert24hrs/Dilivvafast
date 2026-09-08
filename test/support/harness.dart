import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Wraps a screen in the app's real theme and a [ProviderScope].
///
/// Screens read semantic colours through `context.palette`, so pumping them
/// under a bare `MaterialApp` would exercise the fallback palette rather than
/// the themes the app actually ships.
Widget wrapScreen(Widget screen, {ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: screen,
    ),
  );
}
