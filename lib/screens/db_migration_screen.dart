import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/data/services/user_role_service.dart';

class DbMigrationScreen extends StatefulWidget {
  const DbMigrationScreen({super.key});

  @override
  State<DbMigrationScreen> createState() => _DbMigrationScreenState();
}

class _DbMigrationScreenState extends State<DbMigrationScreen> {
  bool _isLoading = false;
  bool _isAdmin = false;
  final _supabase = Supabase.instance.client;
  final List<String> _results = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await UserRoleService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Get.offAllNamed('/home');
    }
  }

  Future<void> _runProfileTableMigration() async {
    setState(() {
      _isLoading = true;
      _results.add('Running profile table migration...');
    });

    try {
      // Add is_active column to profiles table
      await _supabase.rpc('run_sql', params: {
        'query': '''
          -- Add is_active column to profiles table if it doesn't exist
          DO \$\$
          BEGIN
              IF NOT EXISTS (
                  SELECT 1 
                  FROM information_schema.columns 
                  WHERE table_name = 'profiles' 
                  AND column_name = 'is_active'
              ) THEN
                  ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
              END IF;
          END
          \$\$;
        '''
      });

      _results.add('Added is_active column to profiles table');

      // Set all existing users to active
      await _supabase.rpc('run_sql', params: {
        'query': '''
          UPDATE profiles SET is_active = TRUE WHERE is_active IS NULL;
        '''
      });

      _results.add('Set all existing users to active');

      // Make sure updated_at field exists
      await _supabase.rpc('run_sql', params: {
        'query': '''
          DO \$\$
          BEGIN
              IF NOT EXISTS (
                  SELECT 1 
                  FROM information_schema.columns 
                  WHERE table_name = 'profiles' 
                  AND column_name = 'updated_at'
              ) THEN
                  ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
              END IF;
          END
          \$\$;
        '''
      });

      _results.add('Added updated_at column to profiles table');

      // Add role column if it doesn't exist
      await _supabase.rpc('run_sql', params: {
        'query': '''
          DO \$\$
          BEGIN
              IF NOT EXISTS (
                  SELECT 1 
                  FROM information_schema.columns 
                  WHERE table_name = 'profiles' 
                  AND column_name = 'role'
              ) THEN
                  ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
              END IF;
          END
          \$\$;
        '''
      });

      _results.add('Added role column to profiles table');

      // Set admin role for the admin user
      final adminData = await _supabase
          .from('profiles')
          .select()
          .eq('email', 'sahilbagal877@gmail.com')
          .maybeSingle();

      if (adminData != null) {
        await _supabase
            .from('profiles')
            .update({'role': 'admin'}).eq('email', 'sahilbagal877@gmail.com');
        _results.add('Set admin role for sahilbagal877@gmail.com');
      } else {
        _results.add('Warning: sahilbagal877@gmail.com user not found');
      }

      _results.add('Migration completed successfully!');
    } catch (e) {
      _results.add('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Database Migration',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isAdmin
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Migration Utility',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use this utility to run database migrations for the admin panel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runProfileTableMigration,
                    icon: const Icon(Icons.storage),
                    label: const Text('Run Profile Table Migration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8C100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Results:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    result,
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 13,
                                      color: result.contains('Error')
                                          ? Colors.red
                                          : result.contains('Warning')
                                              ? Colors.orange[700]
                                              : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
