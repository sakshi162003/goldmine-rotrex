import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:best/widgets/empty_state.dart';
import 'package:best/widgets/bottom_nav_bar.dart';
import 'package:best/screens/filter_page.dart';
import 'package:best/screens/property_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/presentation/controllers/auth_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();
  bool _isLoading = true;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _supabase
            .from('properties')
          .select('*, property_photos(photo_url, photo_order)')
          .order('created_at', ascending: false);

      if (response != null) {
        properties = List<Map<String, dynamic>>.from(response).map((property) {
          String city = property['city'] ?? 'Unknown City';
          String title = property['title'] ?? 'Property';
          String price = property['price'] != null
              ? '₹${property['price']}'
              : 'Price on request';
          
          // Get the first image URL from property_photos if available
          String image = 'assets/image1.jpg'; // Default image
          if (property['property_photos'] != null && 
              property['property_photos'].isNotEmpty) {
            // Sort photos by photo_order and get the first one
            final sortedPhotos = List<Map<String, dynamic>>.from(property['property_photos'])
                ..sort((a, b) => (a['photo_order'] ?? 0).compareTo(b['photo_order'] ?? 0));
            image = sortedPhotos.first['photo_url'] ?? 'assets/image1.jpg';
          }

          return {
            'id': property['id'] ?? '',
            'name': title,
            'location': city,
            'price': price,
            'type': property['property_type'] ?? 'House',
            'image': image,
            'bedrooms': property['bedrooms']?.toString() ?? '0',
            'bathrooms': property['bathrooms']?.toString() ?? '0',
            'area': property['area'] != null
                ? '${property['area']} sq.ft.'
                : 'Area not specified',
            'isFavorite': false,
            'description': property['description'] ?? '',
            'created_at': property['created_at'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();
      }

      filteredProperties = List.from(properties);
    } catch (e) {
      print('Error loading properties: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProperties = List.from(properties);
      } else {
        filteredProperties = properties
            .where((property) =>
                property['location']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                property['name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _openFilter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterPage(
          initialLocation: '',
          initialType: 'All',
          onApply: (filters) async {
            setState(() {
              _isLoading = true;
            });

            try {
              // Build the query based on filters
              var query = _supabase
                  .from('properties')
                  .select('*, property_photos(photo_url, photo_order)');

              // Add property type filter if not 'All'
              if (filters['propertyType'] != 'All') {
                query = query.eq('property_type', filters['propertyType']);
              }

              // Add location filter if specified
              if (filters['location'] != null && filters['location'].isNotEmpty) {
                query = query.eq('city', filters['location']);
              }

              // Execute the query
              final response = await query.order('created_at', ascending: false);

              if (response != null) {
                // Process the filtered properties
                final filteredProps = List<Map<String, dynamic>>.from(response).map((property) {
                  String city = property['city'] ?? 'Unknown City';
                  String title = property['title'] ?? 'Property';
                  String price = property['price'] != null
                      ? '₹${property['price']}'
                      : 'Price on request';
                  
                  // Get the first image URL from property_photos if available
                  String image = 'assets/image1.jpg'; // Default image
                  if (property['property_photos'] != null && 
                      property['property_photos'].isNotEmpty) {
                    final sortedPhotos = List<Map<String, dynamic>>.from(property['property_photos'])
                        ..sort((a, b) => (a['photo_order'] ?? 0).compareTo(b['photo_order'] ?? 0));
                    image = sortedPhotos.first['photo_url'] ?? 'assets/image1.jpg';
                  }

                  return {
                    'id': property['id'] ?? '',
                    'name': title,
                    'location': city,
                    'price': price,
                    'type': property['property_type'] ?? 'House',
                    'image': image,
                    'bedrooms': property['bedrooms']?.toString() ?? '0',
                    'bathrooms': property['bathrooms']?.toString() ?? '0',
                    'area': property['area'] != null
                        ? '${property['area']} sq.ft.'
                        : 'Area not specified',
                    'isFavorite': false,
                    'description': property['description'] ?? '',
                    'created_at': property['created_at'] ?? DateTime.now().toIso8601String(),
                  };
              }).toList();

                setState(() {
                  filteredProperties = filteredProps;
                  _isLoading = false;
                });

                // Show filter results message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Found ${filteredProps.length} properties matching your criteria',
                      style: GoogleFonts.raleway(),
                    ),
                    backgroundColor: const Color(0xFF7C8500),
                  ),
                );
              }
            } catch (e) {
              print('Error applying filters: $e');
              setState(() {
                _isLoading = false;
            });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error applying filters: ${e.toString()}',
                    style: GoogleFonts.raleway(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C8500)),
            )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTopRow(),
            const SizedBox(height: 16),
            _buildPropertyList(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Search Results',
        style: GoogleFonts.raleway(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF7C8500),
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF7C8500)),
        onPressed: () {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF7C8500)),
          onPressed: _openFilter,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.raleway(color: const Color(0xFF7C8500)),
            decoration: InputDecoration(
              hintText: 'Search for houses',
              hintStyle: GoogleFonts.raleway(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF7C8500)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Found ${filteredProperties.length} estates',
          style: GoogleFonts.raleway(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF7C8500)
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.grid_view,
                  color: isGridView ? const Color(0xFF7C8500) : Colors.grey),
              onPressed: () => setState(() => isGridView = true),
            ),
            IconButton(
              icon: Icon(Icons.list,
                  color: !isGridView ? const Color(0xFF7C8500) : Colors.grey),
              onPressed: () => setState(() => isGridView = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyList() {
    if (filteredProperties.isEmpty) {
      return Expanded(
        child: const EmptyState(),
      );
    }

    return Expanded(
      child: isGridView
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredProperties.length,
              itemBuilder: (context, index) =>
                  _buildPropertyCard(filteredProperties[index], index),
            )
          : ListView.separated(
              itemCount: filteredProperties.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFFE0DCCA), // Light gold color for dividers
                height: 1,
              ),
              itemBuilder: (context, index) =>
                  _buildPropertyCard(filteredProperties[index], index),
            ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: const Color(0xFFF5F4F8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    property['image'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF7C8500),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Image loading error: $error');
                      print('Image URL: ${property['image']}');
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading image',
                              style: GoogleFonts.raleway(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property['name'],
                          style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF7C8500))),
                      Text("\$${property['price']}",
                          style: GoogleFonts.raleway(
                              color: const Color(0xFF7C8500),
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                            "${property['rating']}",
                            style: GoogleFonts.raleway(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                          const Icon(Icons.location_on,
                              color: Color(0xFF7C8500), size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                            property['location'],
                            style: GoogleFonts.raleway(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  // Delete button (only for admin)
                  Obx(() => _authController.isAdmin.value
                      ? GestureDetector(
                          onTap: () => _deleteProperty(property),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
                  // Favorite button
                  GestureDetector(
                onTap: () => _toggleFavorite(index),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      property['isFavorite']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: property['isFavorite'] ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(int index) async {
    final currentProperty = filteredProperties[index];
    final newFavoriteStatus = !(currentProperty['isFavorite'] ?? false);

    // Get Supabase client and current user
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      // User not logged in, prompt to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please log in to save favorites',
            style: GoogleFonts.raleway(),
          ),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () => Get.offAllNamed('/login'),
            textColor: const Color(0xFF7C8500),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }

    // Find the index in the original properties list
    final int originalIndex = properties.indexWhere((p) =>
        p['id'] == currentProperty['id']);

    // Optimistically update UI
    setState(() {
      filteredProperties[index]['isFavorite'] = newFavoriteStatus;

      // Also update in the original properties list
      if (originalIndex != -1) {
        properties[originalIndex]['isFavorite'] = newFavoriteStatus;
      }
    });

    try {
      if (newFavoriteStatus) {
        // Add to favorites
        await client.from('favorites').insert({
          'user_id': user.id,
          'property_id': currentProperty['id'],
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added to favorites',
              style: GoogleFonts.raleway(),
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View All',
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
              textColor: const Color(0xFF7C8500),
            ),
            backgroundColor: Colors.white,
          ),
        );
      } else {
        // Remove from favorites
        await client.from('favorites').delete().match({
          'user_id': user.id,
          'property_id': currentProperty['id'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed from favorites',
              style: GoogleFonts.raleway(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.white,
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');

      // Revert UI change on error
      setState(() {
        filteredProperties[index]['isFavorite'] = !newFavoriteStatus;
        if (originalIndex != -1) {
          properties[originalIndex]['isFavorite'] = !newFavoriteStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.raleway(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProperty(Map<String, dynamic> property) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Property',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this property? This action cannot be undone.',
            style: GoogleFonts.raleway(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.raleway(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.raleway(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final propertyId = property['id'];

      // Delete property photos first (due to foreign key constraint)
      await _supabase
          .from('property_photos')
          .delete()
          .eq('property_id', propertyId);

      // Delete favorites related to this property
      await _supabase
          .from('favorites')
          .delete()
          .eq('property_id', propertyId);

      // Delete property inquiries
      await _supabase
          .from('property_inquiries')
          .delete()
          .eq('property_id', propertyId);

      // Finally, delete the property itself
      await _supabase
          .from('properties')
          .delete()
          .eq('id', propertyId);

      // Remove from local lists
      setState(() {
        properties.removeWhere((p) => p['id'] == propertyId);
        filteredProperties.removeWhere((p) => p['id'] == propertyId);
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property deleted successfully',
              style: GoogleFonts.raleway(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting property: ${e.toString()}',
              style: GoogleFonts.raleway(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
