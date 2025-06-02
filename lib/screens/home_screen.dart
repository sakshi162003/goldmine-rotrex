import 'package:flutter/material.dart';
import 'package:best/widgets/category_button.dart';
import 'package:best/widgets/featured_estate_card.dart';
import 'package:best/widgets/nearby_estate_card.dart';
import 'package:best/widgets/OverlayEstateCard.dart';
import 'package:best/widgets/bottom_nav_bar.dart';
import 'package:best/screens/search_screen.dart';
import 'package:best/screens/property_detail.dart';
import 'package:best/screens/filter_page.dart';
import 'package:best/screens/profile_screen.dart';
import 'package:best/screens/add_listing_page.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as location_package;
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi, min;
import 'dart:async';
import 'package:get/get.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'package:best/screens/edit_property_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    await _authController.verifyAdminStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: const HomeTabContent(),
      ),
      // Show floating action button only for admin users
      floatingActionButton: Obx(() => _authController.isAdmin.value
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddListingPage()),
                );
              },
              label: const Text('Add Property'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFFB8C100),
            )
          : const SizedBox.shrink()),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();
  StreamSubscription<RealtimeChannel>? _propertiesSubscription;

  // State variables
  List<Map<String, dynamic>> _nearbyProperties = [];
  bool _isLoadingProperties = true;
  bool _showAllNearbyProperties = false;

  // Location state variables
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;
  double _searchRadiusKm = 10.0; // Default radius in kilometers

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupPropertiesSubscription();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _propertiesSubscription?.cancel();
    super.dispose();
  }

  void _setupPropertiesSubscription() {
    final channel = _supabase.channel('public:properties')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'properties'),
        (payload, [ref]) {
          // Refresh properties when there are changes
          _loadNearbyProperties(_currentPosition);
        },
      );

    channel.subscribe();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _loadNearbyProperties(_currentPosition);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // Radius of Earth in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));
    return earthRadius * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<void> _loadNearbyProperties([Position? position]) async {
    try {
      setState(() {
        _isLoadingProperties = true;
      });

      // Get user's current location
      if (position == null) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _isLoadingProperties = false;
            _locationError = 'Location services are disabled';
          });
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _isLoadingProperties = false;
              _locationError = 'Location permissions are denied';
            });
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() {
            _isLoadingProperties = false;
            _locationError = 'Location permissions are permanently denied';
          });
          return;
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      // Fetch properties from Supabase
      final response = await _supabase
          .from('properties')
          .select('*, property_photos(photo_url, photo_order)')
          .order('created_at', ascending: false)
          .limit(20);

      if (response == null) {
        setState(() {
          _nearbyProperties = [];
          _isLoadingProperties = false;
        });
        return;
      }

      List<Map<String, dynamic>> propertiesData = List<Map<String, dynamic>>.from(response);

      // Calculate distance for each property and filter nearby ones
      propertiesData = propertiesData.where((property) {
        if (property['latitude'] == null || property['longitude'] == null) {
          return false;
        }

        double propertyLat = property['latitude'] is String
                ? double.tryParse(property['latitude']) ?? 0.0
                : (property['latitude'] ?? 0.0);

        double propertyLng = property['longitude'] is String
                ? double.tryParse(property['longitude']) ?? 0.0
                : (property['longitude'] ?? 0.0);

            double distance = _calculateDistance(
          position!.latitude,
          position!.longitude,
          propertyLat,
          propertyLng,
        );

        // Only include properties within 10km radius
        return distance <= 10.0;
      }).toList();

        // Sort by distance
      propertiesData.sort((a, b) {
        double distanceA = _calculateDistance(
          position!.latitude,
          position!.longitude,
          a['latitude'] is String ? double.tryParse(a['latitude']) ?? 0.0 : (a['latitude'] ?? 0.0),
          a['longitude'] is String ? double.tryParse(a['longitude']) ?? 0.0 : (a['longitude'] ?? 0.0),
        );
        double distanceB = _calculateDistance(
          position!.latitude,
          position!.longitude,
          b['latitude'] is String ? double.tryParse(b['latitude']) ?? 0.0 : (b['latitude'] ?? 0.0),
          b['longitude'] is String ? double.tryParse(b['longitude']) ?? 0.0 : (b['longitude'] ?? 0.0),
        );
        return distanceA.compareTo(distanceB);
      });

      // Format properties for display
      _nearbyProperties = propertiesData.map((property) {
        String city = property['city'] ?? 'Unknown City';
        String title = property['title'] ?? 'Property';
        String price = property['price'] != null
            ? '₹${property['price']}'
            : 'Price on request';
        String bedroom = property['bedrooms']?.toString() ?? '0';
        String bathroom = property['bathrooms']?.toString() ?? '0';
        String area = property['area'] != null
            ? '${property['area']} sq.ft.'
            : 'Area not specified';
        
        // Get the first image URL from property_photos if available
        String image = 'assets/image1.jpg'; // Default image
        if (property['property_photos'] != null && 
            property['property_photos'].isNotEmpty) {
          // Sort photos by photo_order and get the first one
          final sortedPhotos = List<Map<String, dynamic>>.from(property['property_photos'])
              ..sort((a, b) => (a['photo_order'] ?? 0).compareTo(b['photo_order'] ?? 0));
          image = sortedPhotos.first['photo_url'] ?? 'assets/image1.jpg';
        }

        // Calculate distance for display
        double distance = _calculateDistance(
          position!.latitude,
          position!.longitude,
          property['latitude'] is String ? double.tryParse(property['latitude']) ?? 0.0 : (property['latitude'] ?? 0.0),
          property['longitude'] is String ? double.tryParse(property['longitude']) ?? 0.0 : (property['longitude'] ?? 0.0),
        );

        return {
          'id': property['id'] ?? '',
          'name': title,
          'location': city + ' • ${distance.toStringAsFixed(1)} km away',
          'price': price,
          'type': property['property_type'] ?? 'House',
          'image': image,
          'bedrooms': bedroom,
          'bathrooms': bathroom,
          'area': area,
          'isFavorite': false,
          'description': property['description'] ?? '',
          'created_at': property['created_at'] ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      // Check favorite status for all properties
      await _checkFavoriteStatus(_nearbyProperties);

      setState(() {
        _isLoadingProperties = false;
      });
    } catch (e) {
      print('Error loading properties: $e');
      setState(() {
        _isLoadingProperties = false;
        _nearbyProperties = [];
        _locationError = 'Error loading properties: $e';
      });
    }
  }

  void _viewAllProperties() {
    setState(() {
      _showAllNearbyProperties = true;
    });
  }

  void _contactViaWhatsApp() {
    if (!_formKey.currentState!.validate()) return;

    // Construct WhatsApp message
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final message = _messageController.text;

    final whatsappMessage = '''
*New Contact from Real Estate App*
-----------------
*Name:* $name
*Email:* $email
*Phone:* $phone
-----------------
*Message:* 
$message
-----------------
    ''';

    // Replace with your admin WhatsApp number
    final adminPhone =
        '912345678910'; // Format: country code + phone number without +

    // Encode message for URL
    final encodedMessage = Uri.encodeComponent(whatsappMessage);

    // Create WhatsApp URL
    final whatsappUrl = 'https://wa.me/$adminPhone?text=$encodedMessage';

    // Launch WhatsApp
    launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);

    // Clear form
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening WhatsApp to send your message'),
        backgroundColor: Color(0xFF7C8500),
      ),
    );
  }

  void _navigateToPropertyDetails(String propertyId) async {
    try {
      // Fetch the complete property data including photos
      final response = await _supabase
          .from('properties')
          .select('*, property_photos(*)')
          .eq('id', propertyId)
          .single();

      if (response != null) {
        // Format the property data
        final property = {
          'id': response['id'] ?? '',
          'name': response['title'] ?? 'Property',
          'location': response['city'] ?? 'Unknown City',
          'price': response['price'] != null ? '₹${response['price']}' : 'Price on request',
          'type': response['property_type'] ?? 'House',
          'bedrooms': response['bedrooms']?.toString() ?? '0',
          'bathrooms': response['bathrooms']?.toString() ?? '0',
          'area': response['area'] != null ? '${response['area']} sq.ft.' : 'Area not specified',
          'isFavorite': false,
          'description': response['description'] ?? '',
          'created_at': response['created_at'] ?? DateTime.now().toIso8601String(),
          'image': response['property_photos'] != null && 
                  response['property_photos'].isNotEmpty
              ? response['property_photos'][0]['photo_url']
              : 'assets/image1.jpg',
        };

        // Navigate to property details and wait for result
        final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsPage(property: property),
      ),
    );

        // If property was edited (result is true), refresh the properties list
        if (result == true) {
          _loadNearbyProperties();
        }
      }
    } catch (e) {
      print('Error fetching property details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading property details: $e'),
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

  Future<void> _togglePropertyFavorite(Map<String, dynamic> property) async {
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

    try {
      // Get the property ID and ensure it's valid
      final propertyId = property['id'];

      if (propertyId == null) {
        throw Exception('Property ID is missing');
      }

      // Check if the property is already in favorites
      final response = await client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (response != null) {
        // Remove from favorites
        await client.from('favorites').delete().match({
          'user_id': user.id,
          'property_id': propertyId,
        });

        // Update UI state
          setState(() {
          // Update in nearby properties
          int nearbyIndex = _nearbyProperties.indexWhere((p) => p['id'] == propertyId);
          if (nearbyIndex != -1) {
            _nearbyProperties[nearbyIndex]['isFavorite'] = false;
          }
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
      } else {
        // Add to favorites
        await client.from('favorites').insert({
          'user_id': user.id,
          'property_id': propertyId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update UI state
          setState(() {
          // Update in nearby properties
          int nearbyIndex = _nearbyProperties.indexWhere((p) => p['id'] == propertyId);
          if (nearbyIndex != -1) {
            _nearbyProperties[nearbyIndex]['isFavorite'] = true;
          }
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
      }
    } catch (e) {
      print('Error toggling favorite status: $e');
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

  // Add this method to check favorite status when loading properties
  Future<void> _checkFavoriteStatus(List<Map<String, dynamic>> properties) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Get all favorites for the current user
      final favorites = await _supabase
          .from('favorites')
          .select('property_id')
          .eq('user_id', user.id);

      if (favorites != null) {
        // Create a set of favorite property IDs for quick lookup
        final favoriteIds = Set<String>.from(
            favorites.map((f) => f['property_id'].toString()));

        // Update the favorite status for each property
        setState(() {
          for (var property in properties) {
            property['isFavorite'] = favoriteIds.contains(property['id'].toString());
          }
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  // Add this method to provide mock data
  List<Map<String, dynamic>> _getMockNearbyProperties() {
    return [
      {
        'id': '1',
        'name': '3 BHK Apartment',
        'location': 'Pune • 2.3 km away',
        'price': '₹45L',
        'type': 'Apartment',
        'bedrooms': '3',
        'bathrooms': '2',
        'area': '1800 sq.ft.',
        'image':
            'https://images.unsplash.com/photo-1480074568708-e7b720bb3f09?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1474&q=80',
        'isFavorite': false,
      },
      {
        'id': '2',
        'name': 'Villa with Garden',
        'location': 'Pune • 3.5 km away',
        'price': '₹95L',
        'type': 'Villa',
        'bedrooms': '4',
        'bathrooms': '3',
        'area': '2500 sq.ft.',
        'image':
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
        'isFavorite': false,
      },
    ];
  }

  // Add property deletion method for admin users
  Future<void> _deleteProperty(Map<String, dynamic> property) async {
    try {
      final propertyId = property['id'];

      // Confirm deletion
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

      // First check if this is a mock property (ID is a simple string like "1" or "2")
      if (propertyId is String && propertyId.length < 5) {
        // Just remove from UI for mock data
        setState(() {
          _nearbyProperties.removeWhere((p) => p['id'] == propertyId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Delete the property images first (due to foreign key constraint)
      await _supabase
          .from('property_images')
          .delete()
          .eq('property_id', propertyId);

      // Delete the property amenities (due to foreign key constraint)
      await _supabase
          .from('property_amenities')
          .delete()
          .eq('property_id', propertyId);

      // Delete favorites related to this property
      await _supabase.from('favorites').delete().eq('property_id', propertyId);

      // Delete the property
      await _supabase.from('properties').delete().eq('id', propertyId);

      // Remove from UI
      setState(() {
        _nearbyProperties.removeWhere((p) => p['id'] == propertyId);
      });

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

  // Add method to delete featured estate
  Future<void> _deleteFeaturedEstate(String id) async {
    try {
      // Confirm deletion
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Featured Property',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this featured property? This action cannot be undone.',
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

      // For demo purposes just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Featured property deleted successfully'),
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

  // Method to navigate to the edit property page
  void _editProperty(Map<String, dynamic> property) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPropertyPage(
          propertyId: property['id'].toString(),
          propertyData: property,
        ),
      ),
    );

    // Refresh properties after returning from edit page
    _loadNearbyProperties();
  }

  // Update to use the Obx widget for reactive updates
  Widget _buildFeaturedEstatesSection() {
    return Obx(() {
      final isAdmin = _authController.isAdmin.value;
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFeaturedProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C8500)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading featured properties',
                style: GoogleFonts.raleway(color: Colors.red),
              ),
            );
          }

          final featuredProperties = snapshot.data ?? [];

          if (featuredProperties.isEmpty) {
            return Center(
              child: Text(
                'No featured properties available',
                style: GoogleFonts.raleway(color: Colors.grey),
              ),
            );
          }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
              children: featuredProperties.map((property) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
              onTap: () {
                      _navigateToPropertyDetails(property['id']);
              },
              child: FeaturedEstateCard(
                      imageUrl: property['image'] ?? 'assets/image1.jpg',
                      estateName: property['name'] ?? 'Property',
                      location: property['location'] ?? 'Unknown Location',
                      price: int.tryParse(property['price']?.toString().replaceAll(RegExp(r'[^\d]'), '') ?? '0') ?? 0,
                      propertyId: property['id'],
                      isFavorite: property['isFavorite'] ?? false,
                      onFavorite: (isFavorite) async {
                        await _togglePropertyFavorite({
                          ...property,
                          'isFavorite': isFavorite,
                        });
                      },
                      onDelete: isAdmin ? () => _deleteFeaturedEstate(property['id']) : null,
              ),
            ),
                );
              }).toList(),
        ),
          );
        },
      );
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFeaturedProperties() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*, property_photos(photo_url, photo_order)')
          .order('created_at', ascending: false)
          .limit(3);

      if (response == null) return [];

      List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(response).map((property) {
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
          'image': image,
          'isFavorite': false,
        };
      }).toList();

      // Check favorite status for each property
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final favorites = await _supabase
            .from('favorites')
            .select('property_id')
            .eq('user_id', user.id);

        if (favorites != null) {
          final favoriteIds = Set<String>.from(
              favorites.map((f) => f['property_id'].toString()));

          for (var property in properties) {
            property['isFavorite'] = favoriteIds.contains(property['id'].toString());
          }
        }
      }

      return properties;
    } catch (e) {
      print('Error fetching featured properties: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Admin Dashboard Section (only for admin users)
            Obx(() {
              final isAdmin = _authController.isAdmin.value;
              return isAdmin 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFA8B60B),
                              Color(0xFF52530D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAdminQuickAction(
                                  icon: Icons.add_home,
                                  label: 'Add\nProperty',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AddListingPage()),
                                    );
                                  },
                                ),
                                _buildAdminQuickAction(
                                  icon: Icons.edit,
                                  label: 'Manage\nProperties',
                                  onTap: () {
                                    Get.toNamed('/manage-properties');
                                  },
                                ),
                                _buildAdminQuickAction(
                                  icon: Icons.people,
                                  label: 'Manage\nUsers',
                                  onTap: () {
                                    Get.toNamed('/user-management');
                                  },
                                ),
                                _buildAdminQuickAction(
                                  icon: Icons.dashboard,
                                  label: 'Admin\nPanel',
                                  onTap: () {
                                    Get.toNamed('/admin');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ) 
                : const SizedBox.shrink();
            }),

            // User Profile Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Greeting Text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
              ).createShader(bounds),
              child: const Text(
                'Hey,',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
              ).createShader(bounds),
              child: const Text(
                "Let's start exploring",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              decoration: InputDecoration(
                hintText: 'Search House, Apartment, etc',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilterPage(
                          initialLocation: '', // Default or current location if any
                          initialType: 'All', // Default type or selected one
                          onApply: (filters) {
                            // 🔥 This is where you can handle the result (optional)
                            print('Applied Filters: $filters');
                            // Optionally trigger setState or filter your listings
                          },
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.filter_list, color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Overlay Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _navigateToPropertyDetails('1');
                    },
                    child: const OverlayEstateCard(
                      imageUrl: 'assets/property (1).jpg',
                      title: 'Offers..! ',
                      subtitle: 'All discounts up to 66%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      _navigateToPropertyDetails('2');
                    },
                    child: const OverlayEstateCard(
                      imageUrl: 'assets/property (3).jpg',
                      title: 'Special offer!',
                      subtitle: 'All discounts up to 50%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      _navigateToPropertyDetails('3');
                    },
                    child: const OverlayEstateCard(
                      imageUrl: 'assets/property (4).jpg',
                      title: 'New Land..!!',
                      subtitle: 'All discounts up to 50%',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Featured Estates - UPDATED SECTION
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
              ).createShader(bounds),
              child: const Text(
                'Featured Estates',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            _buildFeaturedEstatesSection(),

            const SizedBox(height: 24),

            // Nearby Estates - UPDATED SECTION
            _buildNearbyPropertiesTitle(),
            const SizedBox(height: 8),

            // Show location status if trying to get location or if there was an error
            if (_isLoadingLocation || _locationError?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Icon(
                      _isLoadingLocation
                          ? Icons.location_searching
                          : Icons.location_off,
                      size: 16,
                      color: _isLoadingLocation ? Colors.grey : Colors.red[300],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Getting your location for nearby properties...'
                            : 'Location unavailable: $_locationError',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLoadingLocation ? Colors.grey : Colors.red[300],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading indicator while fetching properties
            if (_isLoadingProperties)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C8500)),
              )
            else if (_nearbyProperties.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(Icons.home_work, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No nearby properties found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentPosition != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Try increasing your search radius',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Display properties in a grid or list depending on screen size
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _showAllNearbyProperties
                        ? _nearbyProperties.length
                        : _nearbyProperties.length > 4
                            ? 4
                            : _nearbyProperties.length,
                    itemBuilder: (context, index) {
                      return _buildNearbyEstateCard(
                          _nearbyProperties[index], index);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Show More button
                  if (_nearbyProperties.length > 4 && !_showAllNearbyProperties)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAllNearbyProperties = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF988A44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Show More',
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),

                  // Show Less button
                  if (_showAllNearbyProperties && _nearbyProperties.length > 4)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllNearbyProperties = false;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Show Less',
                            style: GoogleFonts.raleway(
                              color: const Color(0xFF988A44),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_upward,
                              color: Color(0xFF988A44), size: 16),
                        ],
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 40),

            // Contact Us Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF988A44).withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
                    ).createShader(bounds),
                    child: const Text(
                      'Contact Us',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Have questions about a property? Send us a message and we\'ll respond as soon as possible.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            prefixIcon:
                                const Icon(Icons.person, color: Color(0xFF7C8500)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7C8500), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon:
                                const Icon(Icons.email, color: Color(0xFF7C8500)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7C8500), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon:
                                const Icon(Icons.phone, color: Color(0xFF7C8500)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7C8500), width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Your Message',
                            prefixIcon:
                                const Icon(Icons.message, color: Color(0xFF7C8500)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7C8500), width: 2),
                            ),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your message';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _contactViaWhatsApp,
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: Text(
                              'Contact via WhatsApp',
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF25D366), // WhatsApp green
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 40),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_work, color: Color(0xFFB8C100), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Real Estate App',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C8500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFooterItem(Icons.privacy_tip_outlined, 'Privacy'),
                      _buildFooterItem(Icons.help_outline, 'Help'),
                      _buildFooterItem(Icons.info_outline, 'About'),
                      _buildFooterItem(Icons.contact_support_outlined, 'Contact'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2023 Real Estate App. All rights reserved.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  // Update the nearby properties title to reflect location
  Widget _buildNearbyPropertiesTitle() {
    if (_isLoadingLocation) {
      return Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
            ).createShader(bounds),
            child: const Text(
              'Finding Nearby Estates...',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF988A44),
            ),
          ),
        ],
      );
    } else if (_locationError?.isNotEmpty == true) {
      return ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
        ).createShader(bounds),
        child: const Text(
          'Popular Estates',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    } else {
      return ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.amber, Color.fromARGB(198, 70, 53, 2)],
        ).createShader(bounds),
        child: const Text(
          'Nearby Estates',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
  }

  // Update widget to display property distance if available
  Widget _buildNearbyEstateCard(Map<String, dynamic> property, int index) {
    // Parse the price string to extract the numeric value
    String priceStr = property['price'] ?? '₹0';
    // Remove any non-numeric characters except for digits
    priceStr = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    // Parse to int, default to 0 if unable to parse
    int priceValue = int.tryParse(priceStr) ?? 0;

    return Obx(() {
      final isAdmin = _authController.isAdmin.value;
      return Stack(
        children: [
          GestureDetector(
            onTap: () => _navigateToPropertyDetails(property['id']),
            child: NearbyEstateCard(
              estateName: property['name'],
              location: property['location'],
              price: priceValue,
              imageUrl: property['image'],
            ),
          ),
          // Add the like button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _togglePropertyFavorite(property),
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
                child: Icon(
                  property['isFavorite']
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 18,
                  color: property['isFavorite'] ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
          // Admin controls
          if (isAdmin)
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                children: [
                  // Edit button
                  GestureDetector(
                    onTap: () => _editProperty(property),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                        Icons.edit,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: () => _deleteProperty(property),
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
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  // Build a quick action button for admin dashboard
  Widget _buildAdminQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Handle footer item tap
      },
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7C8500), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
