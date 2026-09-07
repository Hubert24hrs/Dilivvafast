import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

/// What the UI should do after a mode was requested from the drawer.
sealed class ModeSwitchResult {
  const ModeSwitchResult();
}

/// The user is entitled to the mode and it is now active — navigate to [route].
class ModeSwitched extends ModeSwitchResult {
  const ModeSwitched(this.mode, this.route);

  final AppMode mode;
  final String route;
}

/// The user has not enrolled yet — send them to the onboarding flow at [route].
class ModeEnrollmentRequired extends ModeSwitchResult {
  const ModeEnrollmentRequired(this.mode, this.route);

  final AppMode mode;
  final String route;
}

/// An application is already in review; nothing to do but wait.
class ModeAwaitingReview extends ModeSwitchResult {
  const ModeAwaitingReview(this.mode);

  final AppMode mode;
}

/// Access was declined or withdrawn by an admin.
class ModeUnavailable extends ModeSwitchResult {
  const ModeUnavailable(this.mode, this.reason);

  final AppMode mode;
  final String reason;
}

/// The switch itself failed (offline, permission denied, …).
class ModeSwitchFailed extends ModeSwitchResult {
  const ModeSwitchFailed(this.message);

  final String message;
}

/// Drives movement between the customer, driver and investor surfaces.
///
/// Registration only ever creates a customer. Driver and investor are unlocked
/// afterwards and stay gated on [ModeAccess.approved], which only the backend
/// can grant — the client may write `activeMode`, never `driverStatus`,
/// `investorStatus` or `role`.
class ModeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Onboarding entry points for the modes a customer can request.
  static const _enrollmentRoutes = {
    AppMode.driver: '/driver/apply',
    AppMode.investor: '/investor/join',
  };

  Future<ModeSwitchResult> requestMode(AppMode mode) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      return const ModeSwitchFailed('You need to be signed in to switch modes.');
    }

    if (mode == AppMode.admin) {
      return const ModeUnavailable(
        AppMode.admin,
        'Admin access is granted internally.',
      );
    }

    final access = user.accessFor(mode);
    return switch (access) {
      ModeAccess.approved => _activate(user, mode),
      ModeAccess.pending => ModeAwaitingReview(mode),
      ModeAccess.none => ModeEnrollmentRequired(
          mode,
          _enrollmentRoutes[mode] ?? mode.homeRoute,
        ),
      ModeAccess.rejected => ModeUnavailable(
          mode,
          'Your ${mode.label.toLowerCase()} application was declined. '
              'Contact support if you think this is a mistake.',
        ),
      ModeAccess.suspended => ModeUnavailable(
          mode,
          'Your ${mode.label.toLowerCase()} access is suspended. '
              'Contact support to restore it.',
        ),
    };
  }

  Future<ModeSwitchResult> _activate(UserModel user, AppMode mode) async {
    if (user.activeMode == mode) {
      return ModeSwitched(mode, mode.homeRoute);
    }

    state = const AsyncLoading();
    final result = await ref
        .read(userRepositoryProvider)
        .updateUser(user.uid, {'activeMode': mode.name});

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return ModeSwitchFailed(failure.message);
      },
      (_) {
        state = const AsyncData(null);
        return ModeSwitched(mode, mode.homeRoute);
      },
    );
  }
}

final modeControllerProvider =
    AsyncNotifierProvider<ModeController, void>(ModeController.new);

/// The surface the signed-in user is currently looking at.
///
/// Falls back to customer whenever the stored `activeMode` outruns the user's
/// entitlements, so a revoked driver lands somewhere valid instead of on a
/// dashboard they can no longer load.
final activeModeProvider = Provider<AppMode>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.effectiveMode ?? AppMode.customer;
});
