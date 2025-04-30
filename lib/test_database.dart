import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://vfhmzkrtiifuyxgdcqux.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmaG16a3J0aWlmdXl4Z2RjcXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0OTg2MjksImV4cCI6MjA2MTA3NDYyOX0.t7pLpbGTsorpwXwkiU4LwmFxt015XNkU46Rhj7_LiFA',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DatabaseTestScreen(),
    );
  }
}

class DatabaseTestScreen extends StatefulWidget {
  @override
  _DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String status = "Ready to test";
  String detailedLog = "";
  
  Future<void> testSignUp() async {
    setState(() {
      status = "Testing signup...";
      detailedLog = "";
    });
    
    try {
      // Step 1: Sign up a test user
      final email = "test_${DateTime.now().millisecondsSinceEpoch}@example.com";
      final password = "Test123456!";
      
      _log("Signing up user: $email");
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        _log("❌ Auth failed - no user returned");
        setState(() {
          status = "Auth failed";
        });
        return;
      }
      
      _log("✅ Auth successful - user ID: ${authResponse.user!.id}");
      
      // Step 2: Create profile with service role token
      try {
        _log("Creating profile in database...");
        
        // Directly insert profile with public access
        final response = await supabase.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': 'Test User',
          'email': email,
          'phone_number': '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select();
        
        _log("✅ Profile created successfully: ${response.toString()}");
        setState(() {
          status = "Test successful";
        });
      } catch (e) {
        _log("❌ Profile creation failed: $e");
        setState(() {
          status = "Profile creation failed";
        });
      }
    } catch (e) {
      _log("❌ Test failed with error: $e");
      setState(() {
        status = "Test failed";
      });
    }
  }
  
  void _log(String message) {
    print(message); // Also print to console for debugging
    setState(() {
      detailedLog = "$detailedLog\n$message";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: testSignUp,
              child: Text('Test Sign Up Process'),
            ),
            SizedBox(height: 16),
            Text('Detailed Log:'),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(detailedLog),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 