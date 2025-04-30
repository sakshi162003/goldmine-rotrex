import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Middleware to redirect authenticated users away from login/signup screens
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Get current user from Supabase
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    // If user is trying to access login or signup screens but is already logged in,
    // redirect to home page
    if ((route == '/login' || route == '/signup') && currentUser != null) {
      return const RouteSettings(name: '/home');
    }
    
    // If user is trying to access protected routes but is not logged in,
    // redirect to login page
    if ((route?.startsWith('/home') == true || 
         route == '/profile' || 
         route == '/favorites' || 
         route?.startsWith('/admin') == true) && 
        currentUser == null) {
      return const RouteSettings(name: '/login');
    }
    
    // Allow access to the requested route
    return null;
  }
} 