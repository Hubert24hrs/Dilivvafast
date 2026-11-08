import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/domain/repositories/i_user_repository.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/mode_controller.dart';

class _UserRepo implements IUserRepository {
  final updates = <Map<String, dynamic>>[];

  @override
  Future<Either<Failure, Unit>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    updates.add(data);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The reported bug: signed in with an account created by the first version
/// of the app, tapping Driver mode said "You need to be signed in to switch
/// modes" — the profile failed to decode, so the app saw no user.
void main() {
  test(
    'an approved courier with an old-format profile enters Driver mode',
    () async {
      final legacyProfile = normalizeUserData({
        'displayName': 'iheanacho hubert',
        'email': 'someone@example.com',
        'phoneNumber': '+2348000000000',
        'createdAt': '2025-12-03T10:15:30.000Z',
        'role': 'driver',
        'driverStatus': 'approved',
        'walletBalance': 0,
        'referralCode': 'ABC123',
      }, 'u1');
      final repo = _UserRepo();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(UserModel.fromJson(legacyProfile)),
          ),
          userRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Let the profile stream deliver.
      container.listen(currentUserProvider, (_, _) {});
      await container.read(currentUserProvider.future);

      final result = await container
          .read(modeControllerProvider.notifier)
          .requestMode(AppMode.driver);

      expect(result, isA<ModeSwitched>());
      expect((result as ModeSwitched).route, '/driver/home');
      expect(repo.updates.single['activeMode'], 'driver');
    },
  );
}
