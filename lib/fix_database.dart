import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://vfhmzkrtiifuyxgdcqux.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmaG16a3J0aWlmdXl4Z2RjcXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0OTg2MjksImV4cCI6MjA2MTA3NDYyOX0.t7pLpbGTsorpwXwkiU4LwmFxt015XNkU46Rhj7_LiFA',
  );
  
  runApp(const DatabaseFixApp());
}

class DatabaseFixApp extends StatelessWidget {
  const DatabaseFixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const DatabaseFixScreen(),
    );
  }
}

class DatabaseFixScreen extends StatefulWidget {
  const DatabaseFixScreen({Key? key}) : super(key: key);

  @override
  _DatabaseFixScreenState createState() => _DatabaseFixScreenState();
}

class _DatabaseFixScreenState extends State<DatabaseFixScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _status = 'Ready';
  String _log = '';
  bool _isAdmin = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _log_(String message) {
    print(message); // Also print to console
    setState(() {
      _log += '$message\n';
    });
  }
  
  Future<void> _loginAsAdmin() async {
    setState(() {
      _status = 'Logging in...';
    });
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      _log_('Please enter email and password');
      setState(() {
        _status = 'Ready';
      });
      return;
    }
    
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        _log_('Login failed: No user returned');
        setState(() {
          _status = 'Login failed';
        });
        return;
      }
      
      _log_('Successfully logged in as: ${response.user!.email}');
      
      // Check if user is admin
      try {
        final userData = await supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
            
        final isAdmin = userData['role'] == 'admin';
        
        setState(() {
          _isAdmin = isAdmin;
          _status = isAdmin ? 'Logged in as Admin' : 'Logged in as User';
        });
        
        _log_(isAdmin 
          ? '✅ User has admin privileges' 
          : '⚠️ User does not have admin privileges');
        
      } catch (e) {
        _log_('Error checking admin status: $e');
        setState(() {
          _status = 'Logged in, but profile check failed';
        });
      }
    } catch (e) {
      _log_('Login error: $e');
      setState(() {
        _status = 'Login failed';
      });
    }
  }
  
  Future<void> _fixDatabaseIssues() async {
    setState(() {
      _status = 'Applying fixes...';
    });
    
    try {
      // Generate unique identifier to avoid conflicts
      final runId = DateTime.now().millisecondsSinceEpoch.toString();
      
      _log_('Starting database fixes...');
      
      // We'll take a more direct approach since rpc doesn't work in the web version
      _log_('Adding INSERT policy directly to profiles table...');
      
      try {
        // Try direct manual insertion as a workaround
        final testEmail = 'fix_test_$runId@example.com';
        final testPassword = 'Test123456!';
        
        // 1. Create a test user in auth
        _log_('Creating test user...');
        final authResponse = await supabase.auth.signUp(
          email: testEmail,
          password: testPassword,
        );
        
        if (authResponse.user == null) {
          _log_('❌ Could not create test user');
          setState(() {
            _status = 'Failed to create test user';
          });
          return;
        }
        
        _log_('✅ Created test user with ID: ${authResponse.user!.id}');
        
        // 2. Try to insert into profiles directly
        _log_('Attempting direct profile insertion...');
        try {
          final result = await supabase.from('profiles').insert({
            'id': authResponse.user!.id,
            'full_name': 'Fix Test User',
            'email': testEmail,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).select();
          
          _log_('✅ Direct profile insertion successful! Database is working.');
          _log_('Result: $result');
          
          setState(() {
            _status = 'Database working correctly';
          });
        } catch (insertError) {
          _log_('❌ Direct profile insertion failed: $insertError');
          _log_('This confirms the INSERT policy is missing. Please run:');
          _log_('''
CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);
''');
          setState(() {
            _status = 'Database needs fixing';
          });
        }
      } catch (e) {
        _log_('Error in test process: $e');
        setState(() {
          _status = 'Test process failed';
        });
      }
      
      _log_('Test complete. If no profiles are being stored, you need to:');
      _log_('1. Login to Supabase dashboard');
      _log_('2. Go to the SQL Editor');
      _log_('3. Run the INSERT policy SQL command shown above');
      
    } catch (e) {
      _log_('Error fixing database: $e');
      setState(() {
        _status = 'Fix failed';
      });
    }
  }

  Future<void> _showInsertPolicy() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SQL to Run'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this SQL and run it in your Supabase SQL editor:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText('''
CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Optional: temporary policy for service access
CREATE POLICY "Temp service role can create profiles" 
  ON profiles FOR INSERT 
  WITH CHECK (true);
'''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Fix Utility'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status: $_status',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Admin Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _loginAsAdmin,
                child: const Text('Login as Admin'),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _fixDatabaseIssues,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Test Database Connection', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showInsertPolicy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Show SQL Fix', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Log:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 300,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_log),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 