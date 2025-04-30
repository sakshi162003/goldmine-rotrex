import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/domain/entities/user_role.dart';
import 'package:best/data/services/user_role_service.dart';

/// Utility class to check and fix admin user issues
class AdminChecker {
  static final supabase = Supabase.instance.client;
  
  /// Check if the admin user exists and create if needed
  static Future<bool> checkAndCreateAdminUser() async {
    try {
      // 1. Check if admin user exists in auth.users
      final adminEmail = 'sahilbagal877@gmail.com';
      
      // Try to get current user
      final currentUser = supabase.auth.currentUser;
      print('Current user in AdminChecker: ${currentUser?.email}');
      
      if (currentUser == null) {
        print('Error: No authenticated user found in AdminChecker');
        return false;
      }
      
      if (currentUser.email == adminEmail) {
        print('Current user is admin email');
        
        // 2. Check if admin user exists in profiles table
        final profile = await supabase
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();
            
        if (profile == null) {
          print('Admin profile not found, creating...');
          
          try {
            // Create admin profile
            await supabase.from('profiles').insert({
              'id': currentUser.id,
              'full_name': 'Admin User',
              'email': adminEmail,
              'phone_number': '+91 9876543210',
              'role': 'admin',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            
            // Verify profile was created
            final verifyProfile = await supabase
                .from('profiles')
                .select()
                .eq('id', currentUser.id)
                .maybeSingle();
                
            if (verifyProfile == null) {
              print('Error: Failed to create admin profile');
              return false;
            }
            
            print('Admin profile created and verified');
          } catch (e) {
            print('Error creating admin profile: $e');
            return false;
          }
        } else if (profile['role'] != 'admin') {
          print('User exists but not admin, updating role...');
          
          try {
            // Update role to admin
            await supabase
                .from('profiles')
                .update({
                  'role': 'admin',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', currentUser.id);
                
            print('Updated user role to admin');
          } catch (e) {
            print('Error updating admin role: $e');
            return false;
          }
        } else {
          print('Admin profile already exists with admin role');
        }
        
        // 3. Update local user role
        await UserRoleService.saveUserRole(UserRole.admin);
        print('Saved admin role to local storage');
        
        return true;
      } else {
        print('Current user email does not match admin email');
        return false;
      }
    } catch (e) {
      print('Error in admin check: $e');
      return false;
    }
  }
  
  /// Show admin login helper dialog
  static void showAdminLoginHelperDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use these credentials to login as admin:'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText('sahilbagal877@gmail.com'),
              ],
            ),
            Row(
              children: [
                const Text('Password: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText('Sanu@123'),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'If login fails, make sure the admin profile exists in the database.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Go to login screen
              Get.offAllNamed('/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
  
  /// Fix admin login at runtime
  static Future<void> fixAdminLogin() async {
    try {
      // Get the current user
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('No user logged in, cannot fix admin login');
        return;
      }
      
      // Is this the admin email?
      if (currentUser.email == 'sahilbagal877@gmail.com') {
        print('Current user has admin email, fixing admin role');
        
        // Update profile with admin role
        await supabase
            .from('profiles')
            .upsert({
              'id': currentUser.id,
              'full_name': 'Admin User',
              'email': currentUser.email,
              'role': 'admin',
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
            
        // Update local role
        await UserRoleService.saveUserRole(UserRole.admin);
        
        Get.snackbar(
          'Admin Access',
          'Your admin access has been restored',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error fixing admin login: $e');
    }
  }
} 