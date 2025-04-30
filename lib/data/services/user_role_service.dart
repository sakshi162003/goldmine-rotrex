import 'package:shared_preferences/shared_preferences.dart';
import 'package:best/domain/entities/user_role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserRoleService {
  static const String _userRoleKey = 'user_role';

  // Save the user role to SharedPreferences
  static Future<void> saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, UserRoleHelper.roleToString(role));
  }

  // Get the user role from SharedPreferences
  static Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_userRoleKey);

    if (roleStr == null) {
      return UserRole.user; // Default role
    }

    return UserRoleHelper.stringToRole(roleStr);
  }

  // Clear the user role from SharedPreferences
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
  }

  // Check if the user is an admin
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == UserRole.admin;
  }

  // Add this utility method for admin verification in screens
  static Future<bool> verifyAdminAndRedirect(BuildContext context) async {
    final isAdmin = await UserRoleService.isAdmin();

    if (!isAdmin && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Get.offAllNamed('/home');
    }

    return isAdmin;
  }
}
