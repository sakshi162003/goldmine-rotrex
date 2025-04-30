import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:best/domain/entities/user_role.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:get/get.dart';

/// AdminSetup - Utility class to create and verify admin user
class AdminSetup {
  static final supabase = Supabase.instance.client;
  static const adminEmail = 'sahilbagal877@gmail.com';
  static const adminPassword = 'Sahil@123';
  
  /// Create admin account and profile
  static Future<bool> createAdminAccount(BuildContext context) async {
    try {
      // Step 1: Sign up admin user if needed
      User? adminUser;
      
      try {
        // Try signing in first to check if account exists
        final response = await supabase.auth.signInWithPassword(
          email: adminEmail,
          password: adminPassword,
        );
        
        adminUser = response.user;
        
        // If we get here, the admin account already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin account already exists. Checking profile...'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        // Account doesn't exist, create it
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creating admin account...'),
            backgroundColor: Colors.orange,
          ),
        );
        
        final response = await supabase.auth.signUp(
          email: adminEmail,
          password: adminPassword,
        );
        
        adminUser = response.user;
      }
      
      if (adminUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create admin account.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      // Step 2: Create or update admin profile
      try {
        final profile = await supabase
            .from('profiles')
            .select()
            .eq('id', adminUser.id)
            .maybeSingle();
            
        if (profile == null) {
          // Create profile
          await supabase.from('profiles').insert({
            'id': adminUser.id,
            'full_name': 'Admin User',
            'email': adminEmail,
            'phone_number': '+91 9876543210',
            'role': 'admin',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Created admin profile successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (profile['role'] != 'admin') {
          // Update role to admin
          await supabase
              .from('profiles')
              .update({
                'role': 'admin',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', adminUser.id);
              
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updated user to admin role.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin profile already exists with admin role.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Step 3: Set local role to admin
        await UserRoleService.saveUserRole(UserRole.admin);
        
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating admin profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error in admin setup: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
  
  /// Show admin setup dialog
  static void showAdminSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Account Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will set up the admin account with the following credentials:'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(adminEmail),
              ],
            ),
            Row(
              children: [
                const Text('Password: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(adminPassword),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Note: This will create both the auth account and profile if needed.',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await createAdminAccount(context);
              if (result) {
                // If setup was successful, verify if user wants to log in as admin
                _showLoginPrompt(context);
              }
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }
  
  /// Show login prompt after successful admin setup
  static void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Setup Complete'),
        content: const Text('Admin account has been set up successfully. Would you like to log in as admin now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.offAllNamed('/login');
            },
            child: const Text('Log In Now'),
          ),
        ],
      ),
    );
  }
} 