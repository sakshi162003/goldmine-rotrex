import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:best/screens/add_listing_page.dart';
import 'package:best/screens/manage_properties_screen.dart';
import 'package:best/screens/user_management_screen.dart';
import 'package:best/screens/db_migration_screen.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:get/get.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isAdmin = false;
  bool _isLoading = true;
  final _authController = Get.find<AuthController>();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. First check if user is authenticated with Supabase
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user found in admin panel');
        _showAccessDeniedAndRedirect('You need to log in first.');
        return;
      }
      
      // 2. Check local admin status
      final isAdmin = await _authController.verifyAdminStatus();
      
      // 3. Verify against database as well for extra security
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
          
      final hasAdminRoleInDB = profile != null && profile['role'] == 'admin';
      
      if (isAdmin && hasAdminRoleInDB) {
        setState(() {
          _isAdmin = true;
          _isLoading = false;
        });
      } else {
        print('Admin check failed: local=${isAdmin}, db=${hasAdminRoleInDB}');
        _showAccessDeniedAndRedirect('Access denied. Admin privileges required.');
      }
    } catch (e) {
      print('Error in admin status check: $e');
      _showAccessDeniedAndRedirect('Error checking permissions. Please try again.');
    }
  }
  
  void _showAccessDeniedAndRedirect(String message) {
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAllNamed('/home');
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
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _isAdmin 
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Add Property Card
                      _buildActionCard(
                        title: 'Add New Property',
                        icon: Icons.add_home,
                        color: const Color(0xFFB8C100),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddListingPage()),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      // Manage Properties Card
                      _buildActionCard(
                        title: 'Manage Properties',
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ManagePropertiesScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      // User Management Card
                      _buildActionCard(
                        title: 'User Management',
                        icon: Icons.people,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UserManagementScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      // Database Migration Card
                      _buildActionCard(
                        title: 'Database Setup',
                        icon: Icons.storage,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DbMigrationScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Admin Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use this dashboard to manage properties and users. Only admin users have access to these features.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Admin credentials: sahilbagal877@gmail.com / Sanu@123',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Access Denied',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You do not have admin privileges',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Get.offAllNamed('/home'),
                        child: const Text('Go to Home'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
