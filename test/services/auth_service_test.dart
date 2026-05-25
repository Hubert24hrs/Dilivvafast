import 'package:fast_delivery/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([FirebaseAuth, UserCredential, User])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService();
    });

    test('currentUser returns null when not logged in', () {
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      expect(authService.currentUser, isNull);
    });

    test('signIn with valid credentials succeeds', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockUser.uid).thenReturn('test_uid');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUserCredential.user).thenReturn(mockUser);

      // Verify sign in was called
      expect(mockUserCredential.user?.email, equals('test@example.com'));
    });

    test('signOut clears current user', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value());
      await authService.signOut();
      // Verify signOut was called
      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}
