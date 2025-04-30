import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/di/injection_container.dart' as di;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/email_verification.dart';
import 'screens/favorites_screen.dart';
import 'screens/property_detail.dart';
import 'screens/admin_panel.dart';
import 'screens/manage_properties_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/db_migration_screen.dart';
import 'package:best/routes/auth_middleware.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
  await Supabase.initialize(
      url: 'https://vfhmzkrtiifuyxgdcqux.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmaG16a3J0aWlmdXl4Z2RjcXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0OTg2MjksImV4cCI6MjA2MTA3NDYyOX0.t7pLpbGTsorpwXwkiU4LwmFxt015XNkU46Rhj7_LiFA',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // You might want to show an error screen or handle this differently
  }

  // Initialize dependency injection
  try {
  await di.initDependencies();
    print('Dependencies initialized successfully');
  } catch (e) {
    print('Error initializing dependencies: $e');
    // You might want to show an error screen or handle this differently
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authMiddleware = AuthMiddleware();
    
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        primaryColor: const Color(0xFF988A44),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF988A44),
          primary: const Color(0xFF988A44),
        ),
      ),
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(
          name: '/login', 
          page: () => const LoginScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/signup', 
          page: () => const SignupScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/home', 
          page: () => const HomeScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/search', 
          page: () => const SearchPage(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/profile', 
          page: () => const ProfilePage(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/favorites', 
          page: () => const FavoritesScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/admin', 
          page: () => const AdminPanel(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/forgot-password', 
          page: () => const ForgotPasswordScreen()
        ),
        GetPage(
            name: '/email-verification',
          page: () => const EmailVerificationScreen()
        ),
        GetPage(
            name: '/manage-properties',
          page: () => const ManagePropertiesScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/user-management', 
          page: () => const UserManagementScreen(),
          middlewares: [authMiddleware],
        ),
        GetPage(
          name: '/db-migration', 
          page: () => const DbMigrationScreen(),
          middlewares: [authMiddleware],
        ),
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Wait for 3 seconds to show splash screen
      await Future.delayed(const Duration(seconds: 3));
      
      // Check if user is authenticated
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        print('User is already authenticated: ${currentUser.email}');
        
        // Check if profile exists, create if it doesn't
        bool profileExists = await _checkAndCreateProfile(currentUser);
        
        if (!profileExists) {
          print('Profile created for existing auth user');
        }
        
        // Check if user is admin
        final isAdmin = await isUserAdmin();
        
        // Always navigate to home for both admin and regular users
        print('Navigating to home screen');
        Get.offAllNamed('/home');
      } else {
        print('No authenticated user found, redirecting to login');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('Error in authentication check: $e');
      Get.offAllNamed('/login');
    }
  }
  
  // Helper function to check if profile exists and create if it doesn't
  Future<bool> _checkAndCreateProfile(User currentUser) async {
    try {
      // Try to get profile
      final profile = await getCurrentUserProfile();
      
      // If profile exists, return true
      if (profile != null) {
        return true;
      }
      
      // If profile doesn't exist, create it with basic information
      final userData = currentUser.userMetadata;
      final String fullName = userData?['full_name'] ?? 
                              userData?['name'] ?? 
                              currentUser.email?.split('@')[0] ?? 
                              'User';
      
      // Create profile with a retry mechanism
      bool profileCreated = false;
      for (int attempt = 0; attempt < 3 && !profileCreated; attempt++) {
        try {
          // Create profile
          await supabase.from('profiles').insert({
            'id': currentUser.id,
            'full_name': fullName,
            'email': currentUser.email,
            'phone_number': userData?['phone_number'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          // Verify profile was created
          final verifyData = await supabase
              .from('profiles')
              .select()
              .eq('id', currentUser.id)
              .maybeSingle();
              
          if (verifyData != null) {
            profileCreated = true;
            print('Profile created and verified on attempt ${attempt + 1}');
          }
        } catch (e) {
          print('Error on attempt ${attempt + 1} creating profile: $e');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
      
      return profileCreated;
    } catch (e) {
      print('Error checking/creating profile: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/animation/home_animation.json',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// Helper function to get Supabase client
SupabaseClient get supabase => Supabase.instance.client;

// Check if user is authenticated
bool isAuthenticated() {
  return supabase.auth.currentUser != null;
}

// Get current user profile
Future<Map<String, dynamic>?> getCurrentUserProfile() async {
  try {
    if (!isAuthenticated()) return null;
    
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  } catch (e) {
    print('Error getting user profile: $e');
    return null;
  }
}

// Check if user is admin
Future<bool> isUserAdmin() async {
  try {
    final profile = await getCurrentUserProfile();
    return profile != null && profile['role'] == 'admin';
  } catch (e) {
    print('Error checking admin status: $e');
    return false;
  }
}

// 1. Upload Image to Storage
Future<String> uploadImage(dynamic imageFile, String path) async {
  try {
    // Clean up path to prevent double slashes
    final cleanPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${cleanPath.split('/').last}';
    final filePath = '$cleanPath/$fileName';
    
    // Determine which bucket to use based on the path
    String bucketName = 'properties';
    if (cleanPath.contains('avatars') || cleanPath.contains('profile')) {
      bucketName = 'avatars';
    }
    
    // Upload file
    await supabase.storage
        .from(bucketName)
        .upload(filePath, imageFile);
    
    // Get public URL
    final imageUrl = supabase.storage
        .from(bucketName)
        .getPublicUrl(filePath);
    
    return imageUrl;
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

// 2. Download Image from Storage
Future<dynamic> downloadImage(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    
    // Check if the request was successful
    if (response.statusCode != 200) {
      throw Exception('Failed to download image: HTTP ${response.statusCode}');
    }
    
    return response.bodyBytes;
  } catch (e) {
    throw Exception('Failed to download image: $e');
  }
}

// 3. Delete Image from Storage
Future<void> deleteImage(String path) async {
  try {
    // Clean up path to prevent double slashes
    final cleanPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    
    // Determine which bucket to use based on the path
    String bucketName = 'properties';
    if (cleanPath.contains('avatars') || cleanPath.contains('profile')) {
      bucketName = 'avatars';
    }
    
    await supabase.storage
        .from(bucketName)
        .remove([cleanPath]);
  } catch (e) {
    throw Exception('Failed to delete image: $e');
  }
}
