import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to help with Supabase configuration tasks
class SupabaseConfigService {
  final SupabaseClient _supabaseClient;

  SupabaseConfigService({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  /// Helper to sign up a user and automatically sign them in
  /// Bypasses email confirmation requirements
  Future<AuthResponse> signUpAndSignIn({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // First create the user
      final signUpResponse = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: userData,
        emailRedirectTo: null, // This disables redirect
      );
      
      if (signUpResponse.user == null) {
        throw Exception('Failed to create user account');
      }
      
      // Then immediately sign them in
      final signInResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return signInResponse;
    } catch (e) {
      // If there was an error, check if it was just about email confirmation
      if (e.toString().contains('Email not confirmed')) {
        // Try to sign in anyway
        return await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  /// Create a user profile after signup
  /// Returns true if profile was created successfully
  Future<bool> createUserProfile({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      // Try to insert the profile data
      await _supabaseClient.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Verify profile was created
      final data = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      return data != null;
    } catch (e) {
      print('Error creating user profile: $e');
      // We don't throw here because the user might still be created in auth
      return false;
    }
  }
} 