import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gouanzouh/providers/auth_provider.dart';
import 'package:gouanzouh/models/user.dart';
import 'package:gouanzouh/models/shop.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure this is correctly imported
import 'package:logger/logger.dart'; // Import Logger

import 'auth_provider_mockito_test.mocks.dart'; // Import the generated mocks

// Helper to initialize SharedPreferences for testing
// This is a workaround for SharedPreferences.instance which cannot be mocked directly
// In real tests, you might use a package like shared_preferences_platform_interface
// or simply mock its interaction at a higher level.
// For this test, we will clear its static instance.
void _mockSharedPreferences() {
  SharedPreferences.setMockInitialValues({});
}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late AuthProvider authProvider;
  late MockUser mockFirebaseUser;
  late MockUserCredential mockUserCredential;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockShopsCollection;
  late MockDocumentReference mockUserDocRef;
  late MockDocumentReference mockShopDocRef;
  late MockDocumentSnapshot mockUserDocSnapshot;
  late MockDocumentSnapshot mockShopDocSnapshot;
  late MockWriteBatch mockWriteBatch;
  late Logger mockLogger;

  setUp(() {
    _mockSharedPreferences(); // Reset SharedPreferences for each test

    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockFirebaseUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockUsersCollection = MockCollectionReference();
    mockShopsCollection = MockCollectionReference();
    mockUserDocRef = MockDocumentReference();
    mockShopDocRef = MockDocumentReference();
    mockUserDocSnapshot = MockDocumentSnapshot();
    mockShopDocSnapshot = MockDocumentSnapshot();
    mockWriteBatch = MockWriteBatch();
    mockLogger = MockLogger(); // Instantiate mock Logger

    // Stub the logger
    when(mockLogger.i(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
    when(mockLogger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
    when(mockLogger.w(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);
    when(mockLogger.f(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).thenReturn(null);


    // Common stubs
    when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.empty());
    when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value(null));
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(mockUsersCollection.doc(any)).thenReturn(mockUserDocRef);
    when(mockFirestore.collection('shops')).thenReturn(mockShopsCollection);
    when(mockShopsCollection.doc(any)).thenReturn(mockShopDocRef);
    when(mockFirestore.batch()).thenReturn(mockWriteBatch);
    when(mockWriteBatch.commit()).thenAnswer((_) async => Future.value());
    
    // Mock the transaction for register
    when(mockFirestore.runTransaction(any)).thenAnswer((Invocation invocation) async {
      final transactionHandler = invocation.positionalArguments[0] as Future<dynamic> Function(Transaction);
      final mockTransaction = MockTransaction(); // Mock Transaction
      return transactionHandler(mockTransaction);
    });

    authProvider = AuthProvider(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
    );
  });

  group('AuthProvider - Register', () {
    const String testEmail = 'test@example.com';
    const String testPassword = 'Password123!';
    const String testShopName = 'Test Shop';
    const String testUserId = 'testUid';
    const String globalShopId = 'global_shop';

    setUp(() {
      when(mockFirebaseUser.uid).thenReturn(testUserId);
      when(mockFirebaseUser.email).thenReturn(testEmail);
      when(mockUserCredential.user).thenReturn(mockFirebaseUser);

      // Mock createUserWithEmailAndPassword
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUserCredential);
    });

    test('should register a new user and create a new global shop if none exists', () async {
      // Stub shopDoc.exists to return false (shop does not exist)
      when(mockShopDocSnapshot.exists).thenReturn(false);
      when(mockShopDocRef.get()).thenAnswer((_) async => mockShopDocSnapshot);
      when(mockShopDocRef.set(any)).thenAnswer((_) async => Future.value()); // For transaction set
      when(mockUserDocRef.set(any)).thenAnswer((_) async => Future.value()); // For transaction set
      
      final errorMessage = await authProvider.register(testEmail, testPassword, testShopName);

      expect(errorMessage, isNull);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.username, testEmail);
      expect(authProvider.currentUser!.shopId, globalShopId);
      expect(authProvider.currentShop, isNotNull);
      expect(authProvider.currentShop!.name, testShopName);
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      
      // Verify that the shop was attempted to be created
      verify(mockFirestore.runTransaction(any)).called(1);
    });

    test('should register a new user and use existing global shop if it exists', () async {
      // Stub shopDoc.exists to return true (shop exists)
      when(mockShopDocSnapshot.exists).thenReturn(true);
      when(mockShopDocSnapshot.data()).thenReturn({
        'id': globalShopId,
        'ownerId': 'existingOwnerId',
        'name': 'Existing Global Shop',
      });
      when(mockShopDocRef.get()).thenAnswer((_) async => mockShopDocSnapshot);
      when(mockUserDocRef.set(any)).thenAnswer((_) async => Future.value()); // For transaction set

      final errorMessage = await authProvider.register(testEmail, testPassword, testShopName);

      expect(errorMessage, isNull);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.username, testEmail);
      expect(authProvider.currentUser!.shopId, globalShopId);
      expect(authProvider.currentShop, isNotNull);
      expect(authProvider.currentShop!.name, 'Existing Global Shop'); // Should be the existing shop name
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
      
      // Verify that the shop was NOT created, but fetched
      verify(mockFirestore.runTransaction(any)).called(1);
    });

    test('should return error message on FirebaseAuthException during registration', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(auth.FirebaseAuthException(code: 'email-already-in-use'));

      final errorMessage = await authProvider.register(testEmail, testPassword, testShopName);

      expect(errorMessage, 'The email address is already in use by another account.');
      expect(authProvider.currentUser, isNull);
      expect(authProvider.currentShop, isNull);
    });
  });

  group('AuthProvider - Login', () {
    const String testEmail = 'test@example.com';
    const String testPassword = 'Password123!';
    const String testUserId = 'testUid';
    const String testShopId = 'testShopId';
    const String testShopName = 'My Test Shop';

    setUp(() {
      when(mockFirebaseUser.uid).thenReturn(testUserId);
      when(mockFirebaseUser.email).thenReturn(testEmail);
      when(mockUserCredential.user).thenReturn(mockFirebaseUser);

      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockUserCredential);

      // Mock user document data
      when(mockUserDocSnapshot.exists).thenReturn(true);
      when(mockUserDocSnapshot.data()).thenReturn({
        'id': testUserId,
        'username': testEmail,
        'password': '', // Hashed password not stored in Firestore user object
        'role': 'UserRole.client',
        'shopId': testShopId,
      });
      when(mockUserDocRef.get()).thenAnswer((_) async => mockUserDocSnapshot);

      // Mock shop document data
      when(mockShopDocSnapshot.exists).thenReturn(true);
      when(mockShopDocSnapshot.data()).thenReturn({
        'id': testShopId,
        'ownerId': testUserId,
        'name': testShopName,
      });
      when(mockShopDocRef.get()).thenAnswer((_) async => mockShopDocSnapshot);
    });

    test('should log in a user successfully and load shop data', () async {
      final errorMessage = await authProvider.login(testEmail, testPassword);

      expect(errorMessage, isNull);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.username, testEmail);
      expect(authProvider.currentShop, isNotNull);
      expect(authProvider.currentShop!.name, testShopName);
      verify(mockFirebaseAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
    });

    test('should return error message if user data not found after Firebase login', () async {
      when(mockUserDocSnapshot.exists).thenReturn(false); // User data not in Firestore

      final errorMessage = await authProvider.login(testEmail, testPassword);

      expect(errorMessage, "User data not found in database.");
      expect(authProvider.currentUser, isNull);
      expect(authProvider.currentShop, isNull);
    });

    test('should return error message on FirebaseAuthException during login', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(auth.FirebaseAuthException(code: 'wrong-password'));

      final errorMessage = await authProvider.login(testEmail, testPassword);

      expect(errorMessage, 'Wrong password provided.');
      expect(authProvider.currentUser, isNull);
      expect(authProvider.currentShop, isNull);
    });

    test('should attempt offline login if Firebase connection is unavailable', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(auth.FirebaseAuthException(code: 'unavailable'));

      // Mock SharedPreferences for offline login attempt
      SharedPreferences.setMockInitialValues({
        'cached_username': testEmail,
        'cached_password_hash': 'e82c5f111d4d385f0254c7d425b03f0b2f0c7e2c9f5d3d7b4b1a4d8d9f1b0c7e', // _hashPassword('Password123!')
        'cached_user_id': testUserId,
        'cached_role': 'UserRole.client',
        'cached_shop_id': testShopId,
        'cached_shop_name': testShopName,
      });
      
      final errorMessage = await authProvider.login(testEmail, testPassword);

      expect(errorMessage, isNull);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.username, testEmail);
      expect(authProvider.isOfflineMode, isTrue);
      expect(authProvider.currentShop, isNotNull);
      expect(authProvider.currentShop!.name, testShopName);
    });

    test('should return connection error if offline login also fails', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(auth.FirebaseAuthException(code: 'unavailable'));

      // SharedPreferences should not contain credentials for offline login to fail
      SharedPreferences.setMockInitialValues({});
      
      final errorMessage = await authProvider.login(testEmail, testPassword);

      expect(errorMessage, "Connection lost. No offline account found for this email.");
      expect(authProvider.currentUser, isNull);
      expect(authProvider.currentShop, isNull);
      expect(authProvider.isOfflineMode, isFalse);
    });
  });



  group('AuthProvider - Data Fetching', () {
    test('getAllUsers should return a list of users', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocumentSnapshot1 = MockDocumentSnapshot();
      final mockDocumentSnapshot2 = MockDocumentSnapshot();

      when(mockDocumentSnapshot1.data()).thenReturn({
        'id': 'user1',
        'username': 'user1@example.com',
        'password': '',
        'role': 'UserRole.client',
        'shopId': 'shop1',
      });
      when(mockDocumentSnapshot2.data()).thenReturn({
        'id': 'user2',
        'username': 'user2@example.com',
        'password': '',
        'role': 'UserRole.client',
        'shopId': 'shop1',
      });
      when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot1, mockDocumentSnapshot2]);
      when(mockUsersCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      final users = await authProvider.getAllUsers();

      expect(users.length, 2);
      expect(users[0].id, 'user1');
      expect(users[1].id, 'user2');
    });

    test('getAllShops should return a list of shops', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocumentSnapshot1 = MockDocumentSnapshot();
      final mockDocumentSnapshot2 = MockDocumentSnapshot();

      when(mockDocumentSnapshot1.data()).thenReturn({
        'id': 'shop1',
        'ownerId': 'user1',
        'name': 'Shop One',
      });
      when(mockDocumentSnapshot2.data()).thenReturn({
        'id': 'shop2',
        'ownerId': 'user2',
        'name': 'Shop Two',
      });
      when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot1, mockDocumentSnapshot2]);
      when(mockShopsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      final shops = await authProvider.getAllShops();

      expect(shops.length, 2);
      expect(shops[0].id, 'shop1');
      expect(shops[1].id, 'shop2');
    });
  });
}

class MockTransaction extends Mock implements Transaction {}

class MockLogger extends Mock implements Logger {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>>, QueryDocumentSnapshot<Map<String, dynamic>> {}
