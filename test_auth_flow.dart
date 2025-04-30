import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:best/domain/repositories/auth_repository.dart';
import 'package:best/data/repositories/auth_repository_impl.dart';
import 'package:best/domain/entities/user_entity.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// This is a manual test script that can be run to verify the authentication flow.
/// It's not an automated test, but a guide to manually test the app.
///
/// To run this, you would need to adapt it to a main() function or create a test widget.
/// This serves as documentation for testing the auth flow manually.

class AuthFlowTest {
  final SupabaseClient supabase = Supabase.instance.client;
  late AuthRepository authRepository;

  // Test user data
  final testEmail =
      'test_user_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final testPassword = 'Password123!';
  final testName = 'Test User';
  final testPhone = '1234567890';

  AuthFlowTest() {
    // Initialize repository
    authRepository = AuthRepositoryImpl(
      supabaseClient: supabase,
      googleSignIn: GoogleSignIn(),
    );
  }

  /// Run all tests in sequence
  Future<void> runAllTests() async {
    print('🔍 Starting Auth Flow Tests');

    try {
      // Sign up
      print('\n1️⃣ Testing Sign Up');
      final signUpResult = await testSignUp();

      // Sign in
      print('\n2️⃣ Testing Sign In');
      final signInResult = await testSignIn();

      // Get current user
      print('\n3️⃣ Testing Get Current User');
      final currentUser = await testGetCurrentUser();

      // Reset password (optional, will send email)
      // print('\n4️⃣ Testing Reset Password');
      // await testResetPassword();

      // Sign out
      print('\n5️⃣ Testing Sign Out');
      await testSignOut();

      print('\n✅ All tests completed successfully!');
    } catch (error) {
      print('\n❌ Test failed with error: $error');
    }
  }

  /// Test the sign up functionality
  Future<UserEntity> testSignUp() async {
    print('📝 Signing up with: $testEmail');

    try {
      final user = await authRepository.signUp(
        email: testEmail,
        password: testPassword,
        fullName: testName,
        phoneNumber: testPhone,
      );

      print('✅ Sign up successful');
      print('👤 User ID: ${user.id}');
      print('📧 Email: ${user.email}');
      print('👋 Name: ${user.fullName}');

      return user;
    } catch (error) {
      print('❌ Sign up failed: $error');
      rethrow;
    }
  }

  /// Test the sign in functionality
  Future<UserEntity> testSignIn() async {
    print('🔑 Signing in with: $testEmail');

    try {
      final user = await authRepository.signIn(
        email: testEmail,
        password: testPassword,
      );

      print('✅ Sign in successful');
      print('👤 User ID: ${user.id}');
      print('📧 Email: ${user.email}');

      return user;
    } catch (error) {
      print('❌ Sign in failed: $error');
      rethrow;
    }
  }

  /// Test getting the current user
  Future<UserEntity?> testGetCurrentUser() async {
    print('👀 Getting current user');

    try {
      final user = await authRepository.getCurrentUser();

      if (user != null) {
        print('✅ Current user retrieved');
        print('👤 User ID: ${user.id}');
        print('📧 Email: ${user.email}');
      } else {
        print('❌ No current user found');
      }

      return user;
    } catch (error) {
      print('❌ Get current user failed: $error');
      rethrow;
    }
  }

  /// Test password reset (will send an actual email)
  Future<void> testResetPassword() async {
    print('🔄 Requesting password reset for: $testEmail');

    try {
      await authRepository.resetPassword(email: testEmail);
      print('✅ Password reset email sent');
    } catch (error) {
      print('❌ Password reset failed: $error');
      rethrow;
    }
  }

  /// Test signing out
  Future<void> testSignOut() async {
    print('🚪 Signing out');

    try {
      await authRepository.signOut();

      // Verify we're signed out by trying to get current user
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        print('✅ Sign out successful');
      } else {
        print('❌ Sign out failed: User still logged in');
        throw Exception('User still logged in after sign out');
      }
    } catch (error) {
      print('❌ Sign out failed: $error');
      rethrow;
    }
  }
}

// How to use this test class:
// 
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   
//   await Supabase.initialize(
//     url: 'YOUR_SUPABASE_URL',
//     anonKey: 'YOUR_SUPABASE_ANON_KEY',
//   );
//   
//   final tester = AuthFlowTest();
//   await tester.runAllTests();
// } 