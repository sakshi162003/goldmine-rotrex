import 'package:best/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Sign up a new user with email and password
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  /// Sign in an existing user with email and password
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth
  Future<UserEntity> signInWithGoogle();

  /// Reset password for an email
  Future<void> resetPassword({required String email});

  /// Sign out the current user
  Future<void> signOut();

  /// Get the current authenticated user
  Future<UserEntity?> getCurrentUser();
}
