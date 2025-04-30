import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Import your screens here
// import 'screens/login_screen.dart';
// import 'screens/home_screen.dart';
// etc...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL_HERE', // Replace with your Supabase URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY_HERE', // Replace with your Supabase anon key
  );

  // Initialize dependency injection
  // await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        primaryColor: const Color(0xFF988A44), // You can change this color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF988A44), // You can change this color
        ),
      ),
      getPages: [
        // Define your routes here
        // GetPage(name: '/', page: () => const SplashScreen()),
        // GetPage(name: '/login', page: () => const LoginScreen()),
        // etc...
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
    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/animation/home_animation.json', // Replace with your animation
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// Storage functions for your new project
Future<String> uploadImage(File imageFile, String path) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
    final filePath = '$path/$fileName';
    
    // Upload file
    await Supabase.instance.client.storage
        .from('YOUR_BUCKET_NAME') // Replace with your bucket name
        .upload(filePath, imageFile);
    
    // Get public URL
    final imageUrl = Supabase.instance.client.storage
        .from('YOUR_BUCKET_NAME') // Replace with your bucket name
        .getPublicUrl(filePath);
    
    return imageUrl;
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

Future<File> downloadImage(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;
    
    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/image.jpg');
    await file.writeAsBytes(bytes);
    
    return file;
  } catch (e) {
    throw Exception('Failed to download image: $e');
  }
}

Future<void> deleteImage(String path) async {
  try {
    await Supabase.instance.client.storage
        .from('YOUR_BUCKET_NAME') // Replace with your bucket name
        .remove([path]);
  } catch (e) {
    throw Exception('Failed to delete image: $e');
  }
}

// Repository example for your new project
class PropertyRepository {
  final SupabaseClient _supabase;

  PropertyRepository(this._supabase);

  // Get all properties
  Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await _supabase
        .from('properties')
        .select('*, property_images(*)')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Add new property with images
  Future<void> addProperty(Map<String, dynamic> property, List<File> images) async {
    // Start transaction
    final propertyId = await _supabase
        .from('properties')
        .insert(property)
        .select('id')
        .single();

    // Upload images
    for (var image in images) {
      final imageUrl = await uploadImage(
        image, 
        'properties/${propertyId['id']}'
      );

      await _supabase
          .from('property_images')
          .insert({
            'property_id': propertyId['id'],
            'image_url': imageUrl,
          });
    }
  }

  // Get user's favorites
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('favorites')
        .select('*, properties(*), property_images(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
} 