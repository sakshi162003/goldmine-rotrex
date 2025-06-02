import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:best/widgets/empty_state.dart';
import 'package:best/widgets/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:best/screens/property_detail.dart';
import 'package:get/get.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool isGridView = true;
  bool isLoading = true;
  List<Map<String, dynamic>> favoriteProperties = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        // User not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in to view your favorites'),
            action: SnackBarAction(
              label: 'Sign In',
              onPressed: () => Get.offAllNamed('/login'),
            ),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Attempt to fetch favorites from Supabase
      final response = await client
          .from('favorites')
          .select('property_id, created_at')
          .eq('user_id', user.id);

      // Get all property IDs from favorites
      final propertyIds = response.map((item) => item['property_id']).toList();

      // Fetch properties with their photos using the IDs
      final propertiesResponse = await client
          .from('properties')
          .select('*, property_photos(*)')
          .in_('id', propertyIds);

      // Process response and format properties
      List<Map<String, dynamic>> formattedProperties = [];

      for (var property in propertiesResponse) {
        // Get the first photo URL if available
        String imageUrl = 'assets/image1.jpg'; // Default image
        if (property['property_photos'] != null && 
            property['property_photos'].isNotEmpty) {
          imageUrl = property['property_photos'][0]['photo_url'] ?? 'assets/image1.jpg';
        }

          // Format the property data for display
          formattedProperties.add({
            'id': property['id'],
            'name': property['title'] ?? 'Property',
            'price': property['price'] ?? 0,
            'location': property['city'] != null && property['state'] != null
                ? '${property['city']}, ${property['state']}'
                : property['city'] ?? property['state'] ?? 'Unknown location',
            'type': property['property_type'] ?? 'House',
            'bedrooms': property['bedrooms'] ?? 0,
            'bathrooms': property['bathrooms'] ?? 0,
          'image': imageUrl,
            'isFavorite': true,
          'created_at': property['created_at'],
          'property_photos': property['property_photos'] ?? [],
          });
      }

      setState(() {
        favoriteProperties = formattedProperties;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching favorites: $e');

      setState(() {
        favoriteProperties = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading favorites: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleFavorite(int index) async {
    if (index >= favoriteProperties.length) return;

    final property = favoriteProperties[index];

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null) {
        // Remove from database first
        await client.from('favorites').delete().match({
          'user_id': user.id,
          'property_id': property['id'],
        });

        // Then remove from UI
        setState(() {
          favoriteProperties.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('Error removing favorite: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: GoogleFonts.raleway(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7C8500),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isGridView ? Icons.view_list : Icons.grid_view,
              color: const Color(0xFF7C8500),
            ),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C8500),
              ),
            )
          : _buildContent(),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildContent() {
    if (favoriteProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Properties you favorite will appear here for easy access',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Get.toNamed('/search');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C8500),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Browse Properties',
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isGridView
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: favoriteProperties.length,
              itemBuilder: (context, index) =>
                  _buildPropertyCard(favoriteProperties[index], index),
            )
          : ListView.separated(
              itemCount: favoriteProperties.length,
              itemBuilder: (context, index) =>
                  _buildPropertyCard(favoriteProperties[index], index),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, int index) {
    return GestureDetector(
      onTap: () async {
        // Navigate to property details and wait for result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );

        // If property was edited (result is true), refresh the favorites list
        if (result == true) {
          _loadFavorites();
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Colors.white,
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property['name'],
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${property['price']}/month",
                        style: GoogleFonts.raleway(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: const Color(0xFF7C8500), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property['location'],
                              style: GoogleFonts.raleway(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
              child: GestureDetector(
                onTap: () => _toggleFavorite(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
