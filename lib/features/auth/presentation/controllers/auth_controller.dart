import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithEmail(email: email, password: password);
      result.fold(
        (failure) => throw Exception(failure.message),
        (user) => null, // Success — authStateProvider will react
      );
    });
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).register(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password,
            role: role,
            referralCode: referralCode,
          );
      result.fold(
        (failure) => throw Exception(failure.message),
        (user) => null,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(authRepositoryProvider).loginWithGoogle();
      result.fold(
        (failure) => throw Exception(failure.message),
        (user) => null,
      );
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(authRepositoryProvider).loginWithApple();
      result.fold(
        (failure) => throw Exception(failure.message),
        (user) => null,
      );
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(authRepositoryProvider).resetPassword(email);
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).logout();
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    });
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
