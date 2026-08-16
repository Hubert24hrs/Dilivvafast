import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dilivvafast/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

import 'signup_role_test.mocks.dart';

/// Sign-up must never grant a privileged role.
///
/// The register screen still lets someone pick "Driver" or "Investor", but the
/// picked role is only an intent: it is recorded as `requestedRole` and the
/// account itself is always created as a customer. Elevated roles come from
/// server-side code after review.
///
/// Before this, the picked role was written straight into the user document
/// and firestore.rules only blocked role changes on *update* — so "admin" was
/// one dropdown selection away.
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
])
void main() {
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    usersCollection = MockCollectionReference<Map<String, dynamic>>();
    userDoc = MockDocumentReference<Map<String, dynamic>>();

    final credential = MockUserCredential();
    final user = MockUser();
    when(user.uid).thenReturn('new_user_uid');
    when(user.updateDisplayName(any)).thenAnswer((_) async {});
    when(credential.user).thenReturn(user);
    when(
      auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer((_) async => credential);

    when(firestore.collection('users')).thenReturn(usersCollection);
    when(usersCollection.doc(any)).thenReturn(userDoc);
    when(userDoc.set(any)).thenAnswer((_) async {});

    repository = FirebaseAuthRepository(auth: auth, firestore: firestore);
  });

  /// The document the repository wrote for the new account.
  Map<String, dynamic> capturedUserDocument() {
    return verify(userDoc.set(captureAny)).captured.single
        as Map<String, dynamic>;
  }

  Future<void> registerAs(UserRole role) async {
    await repository.register(
      fullName: 'Ada Obi',
      email: 'ada@example.com',
      phone: '+2348012345678',
      password: 'Password123',
      role: role,
    );
  }

  group('register', () {
    test('creates a customer when signing up as a customer', () async {
      await registerAs(UserRole.customer);

      expect(capturedUserDocument()['role'], 'customer');
    });

    test('creates a customer even when driver is requested', () async {
      await registerAs(UserRole.driver);

      final document = capturedUserDocument();
      expect(document['role'], 'customer');
      expect(document['requestedRole'], 'driver');
    });

    test('creates a customer even when investor is requested', () async {
      await registerAs(UserRole.investor);

      final document = capturedUserDocument();
      expect(document['role'], 'customer');
      expect(document['requestedRole'], 'investor');
    });

    test('cannot be talked into creating an admin', () async {
      // The register screen hides admin, but the repository is the boundary
      // that has to hold regardless of what the UI offers.
      await registerAs(UserRole.admin);

      expect(capturedUserDocument()['role'], 'customer');
    });

    test('records no requestedRole for a plain customer sign-up', () async {
      await registerAs(UserRole.customer);

      expect(capturedUserDocument().containsKey('requestedRole'), isFalse);
    });

    test('starts every account with an empty wallet', () async {
      // firestore.rules rejects a sign-up that opens with a non-zero balance.
      await registerAs(UserRole.driver);

      expect(capturedUserDocument()['walletBalance'], 0.0);
    });

    test('never writes server-owned verification or rating fields', () async {
      await registerAs(UserRole.driver);

      final document = capturedUserDocument();
      expect(document.containsKey('isVerifiedDriver'), isFalse);
      expect(document.containsKey('averageRating'), isFalse);
      expect(document.containsKey('totalRatings'), isFalse);
    });
  });

  group('UserModel', () {
    test('defaults to the customer role', () {
      final now = DateTime(2026, 1, 1);
      final user = UserModel(
        uid: 'u1',
        fullName: 'Ada Obi',
        email: 'ada@example.com',
        phone: '+2348012345678',
        referralCode: 'ADA123',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.role, UserRole.customer);
    });
  });
}
