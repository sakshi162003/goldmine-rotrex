import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:best/widgets/empty_state.dart';
import 'package:best/widgets/bottom_nav_bar.dart';
import 'package:best/screens/filter_page.dart';
import 'package:best/screens/property_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> locationSuggestions = [
    'Wagholi',
    'Viman Nagar',
    'Kharadi',
    'Hinjewadi',
    'Baner',
    'Koregaon Park',
    'Hadapsar',
    'Pashan',
    'Kondhwa',
    'Shivaji Nagar',
  ];

  final List<String> propertyImages = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    'assets/image4.jpg',
  ];

  late List<Map<String, dynamic>> properties;
  late List<Map<String, dynamic>> filteredProperties;

  @override
  void initState() {
    super.initState();
    properties = List.generate(
      24,
      (index) => {
        'name': 'House ${index + 1}',
        'price': 200 + index * 10,
        'location': locationSuggestions[index % locationSuggestions.length],
        'rating': 4.5 + (index % 5) * 0.1,
        'image': propertyImages[index % propertyImages.length],
        'isFavorite': false,
        'type': ['House', 'Apartment', 'Villa'][index % 3],
      },
    );
    filteredProperties = List.from(properties);
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
          onApply: (filters) {
            setState(() {
              // Apply the filters
              filteredProperties = properties.where((property) {
                bool matchesLocation = filters['location'].isEmpty ||
                    property['location'] == filters['location'];
                bool matchesType = filters['propertyType'] == 'All' ||
                    property['type'] == filters['propertyType'];
                return matchesLocation && matchesType;
              }).toList();
            });
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
      body: Padding(
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
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    'assets/image1.jpg',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 100, color: Colors.red),
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
                      Text("\$${property['price']}/month",
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
              child: GestureDetector(
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
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(int index) async {
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
        p['name'] == currentProperty['name'] &&
        p['location'] == currentProperty['location']);

    // Optimistically update UI
    setState(() {
      filteredProperties[index]['isFavorite'] = newFavoriteStatus;

      // Also update in the original properties list
      if (originalIndex != -1) {
        properties[originalIndex]['isFavorite'] = newFavoriteStatus;
      }
    });

    try {
      // First, we need to ensure the property exists in the properties table
      // with a valid UUID
      String propertyId;

      if (currentProperty['id'] == null ||
          !_isValidUuid(currentProperty['id'])) {
        // Create a new property entry with a valid UUID
        final newProperty = {
          'title': currentProperty['name'],
          'price': currentProperty['price'],
          'city': currentProperty['location'].split(',')[0].trim(),
          'state': currentProperty['location'].contains(',')
              ? currentProperty['location'].split(',')[1].trim()
              : '',
          'property_type': currentProperty['type'] ?? 'House',
          'bedrooms': currentProperty['bedrooms'] ?? 3,
          'bathrooms': currentProperty['bathrooms'] ?? 2,
          'image_url': currentProperty['image'],
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert the property and get the UUID
        final propertyResponse = await client
            .from('properties')
            .insert(newProperty)
            .select('id')
            .single();

        propertyId = propertyResponse['id'];

        // Update the property in our list with the new ID
        setState(() {
          filteredProperties[index]['id'] = propertyId;
          if (originalIndex != -1) {
            properties[originalIndex]['id'] = propertyId;
          }
        });
      } else {
        propertyId = currentProperty['id'];
      }

      if (newFavoriteStatus) {
        // Add to favorites using valid UUID
        await client.from('favorites').insert({
          'user_id': user.id, // This is already a valid UUID
          'property_id': propertyId,
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
          'property_id': propertyId,
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

  // Helper method to check if a string is a valid UUID
  bool _isValidUuid(String str) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }
}
