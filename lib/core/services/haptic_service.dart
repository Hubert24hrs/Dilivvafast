import 'package:flutter/services.dart';

/// Service for haptic feedback
class HapticService {
  /// Light impact (for selections)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact (for button taps)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact (for important actions)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection changed (for pickers)
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate (for errors or notifications)
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Success feedback
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Error feedback
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Warning feedback
  static void warning() {
    HapticFeedback.lightImpact();
  }
}
