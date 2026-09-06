import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Manual Logic Verification (Standalone copy of AuthProvider logic for testing)
String hashPassword(String password) {
  var bytes = utf8.encode(password + "digital_shop_salt"); 
  return sha256.convert(bytes).toString();
}

void main() {
  group('AuthProvider Logic Tests', () {
    test('Password hashing should be consistent and salted', () {
      const pass = "password123";
      final hash1 = hashPassword(pass);
      final hash2 = hashPassword(pass);
      
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(pass))); // Should not be plaintext
    });

    test('Offline credentials matching logic', () {
      const email = "test@example.com";
      const pass = "secret";
      final storedHash = hashPassword(pass);
      
      // Simulation of offline login check
      const inputEmail = "test@example.com";
      const inputPass = "secret";
      final inputHash = hashPassword(inputPass);
      
      expect(inputEmail == email && inputHash == storedHash, isTrue);
    });

    test('Offline credentials security (Wrong Password)', () {
      const email = "test@example.com";
      const pass = "secret";
      final storedHash = hashPassword(pass);
      
      const inputPass = "wrong_password";
      final inputHash = hashPassword(inputPass);
      
      expect(inputHash == storedHash, isFalse);
    });
  });
}
