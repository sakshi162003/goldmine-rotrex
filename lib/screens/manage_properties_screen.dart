import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:best/screens/property_detail.dart';
import 'package:best/screens/add_listing_page.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'package:best/screens/edit_property_page.dart';

class ManagePropertiesScreen extends StatefulWidget {
  const ManagePropertiesScreen({super.key});

  @override
  State<ManagePropertiesScreen> createState() => _ManagePropertiesScreenState();
}

class _ManagePropertiesScreenState extends State<ManagePropertiesScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _properties = [];
  final _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadProperties();
  }

  Future<void> _checkAdminStatus() async {
    await _authController.verifyAdminStatus();
    setState(() {
      _isAdmin = _authController.isAdmin.value;
    });

    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Get.offAllNamed('/home');
    }
  }

  Future<void> _loadProperties() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load all properties with their first image
      final response = await _supabase
          .from('properties')
          .select('*, property_images!inner(image_url)')
          .order('created_at', ascending: false);

      // Process the response to get unique properties with their first image
      final Map<String, Map<String, dynamic>> uniqueProperties = {};

      for (final item in response) {
        final propertyId = item['id'].toString();

        if (!uniqueProperties.containsKey(propertyId)) {
          // Add property with its image
          uniqueProperties[propertyId] = {
            ...item,
            'image_url': item['property_images'][0]['image_url'],
          };
        }
      }

      setState(() {
        _properties = uniqueProperties.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading properties: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProperty(String id) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Property',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this property? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Delete the property images first (due to foreign key constraint)
      await _supabase.from('property_images').delete().eq('property_id', id);

      // Delete the property amenities (due to foreign key constraint)
      await _supabase.from('property_amenities').delete().eq('property_id', id);

      // Delete favorites related to this property
      await _supabase.from('favorites').delete().eq('property_id', id);

      // Delete the property
      await _supabase.from('properties').delete().eq('id', id);

      // Refresh the list
      _loadProperties();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Manage Properties',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadProperties,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddListingPage()),
          );
          _loadProperties(); // Refresh list after returning from add page
        },
        label: const Text('Add Property'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFB8C100),
      ),
      body: _isAdmin
          ? _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _properties.isEmpty
                  ? Center(
                      child: Text(
                        'No properties found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Property Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  property['image_url'] ??
                                      'https://via.placeholder.com/400x200?text=No+Image',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            property['name'] ?? 'Unknown',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '\$${property['price'] ?? 0}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFB8C100),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      property['address'] ?? 'No address',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildFeature(
                                          Icons.bed,
                                          '${property['bedrooms'] ?? 0} Beds',
                                        ),
                                        _buildFeature(
                                          Icons.bathtub,
                                          '${property['bathrooms'] ?? 0} Baths',
                                        ),
                                        _buildFeature(
                                          Icons.square_foot,
                                          '${property['area'] ?? 0} sqft',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PropertyDetailsPage(
                                                    property: {
                                                      'id': property['id']
                                                          .toString(),
                                                      'name': property['name'],
                                                      'price':
                                                          property['price'],
                                                      'description': property[
                                                          'description'],
                                                      'address':
                                                          property['address'],
                                                      'bedrooms':
                                                          property['bedrooms'],
                                                      'bathrooms':
                                                          property['bathrooms'],
                                                      'area': property['area'],
                                                      'image_url':
                                                          property['image_url'],
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('View'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black87,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              // Navigate to edit property page
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditPropertyPage(
                                                    propertyId: property['id']
                                                        .toString(),
                                                    propertyData: property,
                                                  ),
                                                ),
                                              ).then((_) {
                                                // Refresh properties list when returning from edit page
                                                _loadProperties();
                                              });
                                            },
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _deleteProperty(
                                                property['id'].toString()),
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Delete'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
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
                        );
                      },
                    )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
