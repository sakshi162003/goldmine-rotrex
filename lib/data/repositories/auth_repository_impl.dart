import 'package:best/data/models/user_model.dart';
import 'package:best/data/services/supabase_config_service.dart';
import 'package:best/domain/entities/user_entity.dart';
import 'package:best/domain/repositories/auth_repository.dart';
import 'package:best/domain/entities/user_role.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;
  late final SupabaseConfigService _configService;

  AuthRepositoryImpl({
    required SupabaseClient supabaseClient,
    required GoogleSignIn googleSignIn,
  })  : _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn {
    // Get the config service from GetX
    _configService = Get.find<SupabaseConfigService>();
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      print('Starting signup process for: $email');
      
      // Prepare user data
      final userData = {
        'full_name': fullName,
        'phone_number': phoneNumber ?? '',
      };
      
      // Use our helper service to sign up and sign in
      final authResponse = await _configService.signUpAndSignIn(
        email: email,
        password: password,
        userData: userData,
      );
      
      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }
      
      print('User created and signed in with ID: ${authResponse.user!.id}');
      
      // Create profile in database and verify it was created successfully
      await _configService.createUserProfile(
        userId: authResponse.user!.id,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      );
      
      // Verify profile was created by fetching it
      final profileData = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();
          
      if (profileData == null) {
        print('Warning: Profile creation may have failed. Creating fallback profile.');
        // Try one more time with direct insert
        await _supabaseClient.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Return the created user model
      return UserModel(
        id: authResponse.user!.id,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Sign up failed with error: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Helper method to check if the insert policy exists
  Future<bool> _checkIfInsertPolicyExists() async {
    try {
      // This is a workaround to check if we can insert data
      // We create a temporary user and try to insert directly after auth
      final tempEmail = 'temp_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final tempPassword = 'Temp123456!';
      
      final tempAuthResponse = await _supabaseClient.auth.signUp(
        email: tempEmail,
        password: tempPassword,
      );
      
      if (tempAuthResponse.user == null) {
        return false;
      }
      
      try {
        // Try to insert a profile with minimal data
        await _supabaseClient.from('profiles').insert({
          'id': tempAuthResponse.user!.id,
          'full_name': 'Temp User',
          'email': tempEmail,
        }).select();
        
        // If we get here, insertion works
        return true;
      } catch (e) {
        print('Insert policy test failed: $e');
        return false;
      }
    } catch (e) {
      print('Error checking insert policy: $e');
      return false;
    }
  }

  // Send a welcome email to the user
  Future<void> _sendWelcomeEmail(String email, String fullName) async {
    try {
      // This is a simplified example. In a real app, you'd use a proper email service
      // For Supabase, you might use Edge Functions or a separate email service API

      // For now, we'll just print to console that we would send an email
      print('Sending welcome email to $email');

      // Example of how you might call a Supabase Edge Function to send an email
      // await _supabaseClient.functions.invoke('send-welcome-email', {
      //   'email': email,
      //   'fullName': fullName,
      //   'subject': 'Welcome to Goldmine Properties!',
      //   'message': 'Thank you for joining Goldmine Properties! We\'re excited to help you find your perfect property.',
      // });
    } catch (e) {
      print('Failed to send welcome email: ${e.toString()}');
      // Don't throw an exception here - we don't want to fail the signup if the email fails
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign in process for: $email');
      
      // Don't handle admin login here, let the controller handle it
      // This avoids having admin logic in multiple places

      // Sign in with Supabase
      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('Sign in failed: No user returned');
        throw Exception('Sign in failed: No user returned');
      }

      print('User authenticated with ID: ${authResponse.user!.id}');

      try {
        // Try to get existing profile
        final userData = await _supabaseClient
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        print('Found existing profile for user: ${authResponse.user!.id}');
        return UserModel.fromJson(userData);
      } catch (e) {
        // Profile might not exist yet
        print('Profile not found, creating new profile for user: ${authResponse.user!.id}');

        // Create new profile with minimal required fields
        final newProfile = {
          'id': authResponse.user!.id,
          'full_name': authResponse.user!.email!.split('@')[0] ?? 'User',
          'email': authResponse.user!.email!,
          'phone_number': '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await _supabaseClient.from('profiles').insert(newProfile);
          print('Created new profile for user: ${authResponse.user!.id}');
        } catch (insertError) {
          print('Failed to create profile: $insertError');
          // Continue anyway - we'll use the in-memory profile
        }

        return UserModel.fromJson(newProfile);
      }
    } catch (e) {
      print('Sign in error: ${e.toString()}');
      
      // If the error is about email confirmation, proceed with a temporary user model
      if (e.toString().contains('Email not confirmed')) {
        try {
          // Try to get the user from auth anyway
          final currentUser = _supabaseClient.auth.currentUser;
          if (currentUser != null) {
            // Return a basic user model
            return UserModel(
              id: currentUser.id,
              fullName: currentUser.email?.split('@')[0] ?? 'User',
              email: currentUser.email ?? '',
              createdAt: DateTime.now(),
            );
          }
        } catch (_) {
          // Ignore errors here and throw the original exception
        }
      }
      
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;

      // Sign in with Supabase using Google token
      final authResponse = await _supabaseClient.auth.signInWithIdToken(
        provider: Provider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if profile exists
      final data = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      // Create profile if not exists
      if (data == null) {
        await _supabaseClient.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        return UserModel(
          id: authResponse.user!.id,
          fullName: googleUser.displayName ?? '',
          email: googleUser.email,
          createdAt: DateTime.now(),
        );
      }

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final userData = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userData == null) {
        return null;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Get current user failed: ${e.toString()}');
    }
  }
}

