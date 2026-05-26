import 'package:dilivvafast/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([FirebaseAuth, UserCredential, User])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService(
        auth: mockFirebaseAuth,
        googleSignIn: FakeGoogleSignIn(),
      );
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

      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Password123',
      )).thenAnswer((_) async => mockUserCredential);

      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'Password123',
      );

      expect(result.user?.email, equals('test@example.com'));
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);
    });

    test('signOut clears current user', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value());
      await authService.signOut();
      // Verify signOut was called
      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}
