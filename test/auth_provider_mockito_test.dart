import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gouanzouh/providers/auth_provider.dart';
import 'package:gouanzouh/models/user.dart' as model_user;

import 'auth_provider_mockito_test.mocks.dart';

// The build_runner should generate mocks for these
@GenerateMocks([
  auth.FirebaseAuth,
  FirebaseFirestore,
  auth.UserCredential,
  auth.User,
  WriteBatch,
  SharedPreferences,
], customMocks: [
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<Stream<auth.User?>>(as: #MockAuthStream),
])
void main() {
  // Use late to initialize in setUp
  late AuthProvider authProvider;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockUserDocRef;
  late MockDocumentSnapshot mockUserDocSnapshot;
  late MockDocumentReference mockShopDocRef;
  late MockDocumentSnapshot mockShopDocSnapshot;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late MockAuthStream mockAuthStream;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    // Initialize all mock objects
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockUserDocRef = MockDocumentReference();
    mockUserDocSnapshot = MockDocumentSnapshot();
    mockShopDocRef = MockDocumentReference();
    mockShopDocSnapshot = MockDocumentSnapshot();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockAuthStream = MockAuthStream();
    mockSharedPreferences = MockSharedPreferences();

    // Mock the authStateChanges stream BEFORE the provider is created
    when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream<auth.User?>.empty());

    // Instantiate the provider with mocks
    authProvider = AuthProvider(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
    );
  });

  group('AuthProvider Login', () {
    test('login succeeds with valid credentials', () async {
      // Arrange
      const email = 'test@test.com';
      const password = 'password';
      const uid = 'testuid';
      const shopId = 'testshopid';

      // Mock SharedPreferences
      // SharedPreferences.setMockInitialValues is the official way for tests
      SharedPreferences.setMockInitialValues({'test': 'test'});

      // Mock FirebaseAuth
      when(mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(uid);

      // Mock FirebaseFirestore
      when(mockFirestore.collection('users')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc(uid)).thenReturn(mockUserDocRef);
      when(mockUserDocRef.get()).thenAnswer((_) async => mockUserDocSnapshot);
      when(mockUserDocSnapshot.exists).thenReturn(true);
      when(mockUserDocSnapshot.data()).thenReturn({
        'id': uid,
        'username': email,
        'role': 'UserRole.client',
        'shopId': shopId,
      });

      when(mockFirestore.collection('shops')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc(shopId)).thenReturn(mockShopDocRef);
      when(mockShopDocRef.get()).thenAnswer((_) async => mockShopDocSnapshot);
      when(mockShopDocSnapshot.exists).thenReturn(true);
      when(mockShopDocSnapshot.data()).thenReturn({
        'id': shopId,
        'name': 'Test Shop',
        'ownerId': uid,
      });

      // Act
      final result = await authProvider.login(email, password);

      // Assert
      expect(result, isNull); // Null result means success
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.username, email);
      expect(authProvider.currentShop, isNotNull);
      expect(authProvider.currentShop!.name, 'Test Shop');
      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password)).called(1);
    });

    test('login fails with wrong password', () async {
      // Arrange
      const email = 'test@test.com';
      const password = 'wrong_password';
      
      // Mock FirebaseAuth to throw an exception
      when(mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password))
          .thenThrow(auth.FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password provided for that user.',
      ));

      // Act
      final result = await authProvider.login(email, password);

      // Assert
      expect(result, isNotNull);
      expect(result, 'Wrong password provided.');
      expect(authProvider.currentUser, isNull);
    });
  });
}
