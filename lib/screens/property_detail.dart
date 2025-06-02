import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'edit_property_page.dart';
import 'package:best/widgets/bottom_nav_bar.dart';

// Helper class for location data
class _LocationData {
  final double latitude;
  final double longitude;

  _LocationData(this.latitude, this.longitude);
}

// Get an icon for a place type
IconData _getIconForPlaceType(String type) {
  switch (type.toLowerCase()) {
    case 'school':
      return Icons.school;
    case 'hospital':
      return Icons.local_hospital;
    case 'park':
      return Icons.park;
    case 'shopping mall':
      return Icons.shopping_cart;
    case 'restaurant':
      return Icons.restaurant;
    case 'temple':
      return Icons.temple_buddhist;
    case 'gym':
      return Icons.fitness_center;
    default:
      return Icons.place;
  }
}

class PropertyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();
  bool isFavorite = false;
  bool isLoading = false;
  bool _useStaticMap = false;
  bool _mapLoadError = false;
  String _mapErrorMessage = '';
  late LatLng _propertyLocation;
  GoogleMapController? _mapController;
  final LatLng _defaultLocation =
      const LatLng(17.6805, 74.0183); // Satara, Maharashtra (default)
  int _selectedImageIndex = 0; // Track currently selected thumbnail
  List<Map<String, dynamic>> _propertyPhotos = [];
  bool _isLoadingPhotos = true;
  int _currentImageIndex = 0;
  bool isAdmin = false;
  RealtimeChannel? _propertySubscription;

  // Convert to a Set for the Google Maps markers
  final Set<Marker> _markers = {};
  final List<Map<String, dynamic>> _nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    isFavorite = widget.property['isFavorite'] ?? false;
    _checkIfFavorited();
    _loadPropertyPhotos();
    _checkAdminRole();
    _setupRealtimeSubscription();

    // If the property has an image, make sure it always points to the single image
    if (widget.property.containsKey('image')) {
      widget.property['image'] = 'assets/image1.jpg';
    }

    // Set default location to Satara (fallback location)
    _propertyLocation =
        const LatLng(17.6805, 74.0183); // Satara coordinates as default

    try {
      _initializeLocationData();
    } catch (e) {
      print('Error initializing location data: $e');
      setState(() {
        _useStaticMap = true;
        _mapLoadError = true;
        _mapErrorMessage = e.toString();
      });
    }
  }

  void _setupRealtimeSubscription() {
    final propertyId = widget.property['id'];
    if (propertyId != null) {
      final channel = _supabase
          .channel('property_changes')
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: '*',
              schema: 'public',
              table: 'properties',
              filter: 'id=eq.$propertyId',
            ),
            (payload, [ref]) {
              _handlePropertyUpdate(payload);
            },
          );
      
      _propertySubscription = channel;
      channel.subscribe((status, [err]) {
        if (status == 'SUBSCRIBED') {
          print('Successfully subscribed to property changes');
        } else if (status == 'CHANNEL_ERROR') {
          print('Error subscribing to property changes: $err');
        }
      });
    }
  }

  void _handlePropertyUpdate(Map<String, dynamic> payload) {
    if (payload['type'] == 'UPDATE' && payload['new'] != null) {
      final newData = payload['new'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          widget.property.addAll({
            'id': newData['id'] ?? widget.property['id'],
            'name': newData['title'] ?? widget.property['name'],
            'location': newData['city'] ?? widget.property['location'],
            'price': newData['price'] != null ? '₹${newData['price']}' : widget.property['price'],
            'type': newData['property_type'] ?? widget.property['type'],
            'bedrooms': newData['bedrooms']?.toString() ?? widget.property['bedrooms'],
            'bathrooms': newData['bathrooms']?.toString() ?? widget.property['bathrooms'],
            'area': newData['area'] != null ? '${newData['area']} sq.ft.' : widget.property['area'],
            'description': newData['description'] ?? widget.property['description'],
            'created_at': newData['created_at'] ?? widget.property['created_at'],
            // Add all the fields that are used in specifications section
            'property_type': newData['property_type'] ?? widget.property['property_type'],
            'year_built': newData['year_built']?.toString() ?? widget.property['year_built'],
            'bhk': newData['bhk'] ?? widget.property['bhk'],
            'balconies': newData['balconies']?.toString() ?? widget.property['balconies'],
            'city': newData['city'] ?? widget.property['city'],
            'state': newData['state'] ?? widget.property['state'],
            'country': newData['country'] ?? widget.property['country'],
            'address': newData['address'] ?? widget.property['address'],
            'special_status': newData['special_status'] ?? widget.property['special_status'],
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _propertySubscription?.unsubscribe();
    super.dispose();
  }

  void _initializeLocationData() {
    print('Initializing location data for property map');

    try {
      // Hard-code Satara location based on the provided address
      print('Setting property location to Satara, Powai Naka');
      _propertyLocation =
          const LatLng(17.6892, 74.0014); // Satara, Powai Naka coordinates

      // Clear existing markers
      _markers.clear();

      // Add property marker
      try {
        _markers.add(
          Marker(
            markerId: const MarkerId('property'),
            position: _propertyLocation,
            infoWindow: InfoWindow(
              title: widget.property['name'] ?? 'Property',
              snippet: 'Shop No 3 & 4, Powai Naka, Satara',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
        );
        print(
            'Added property marker at ${_propertyLocation.latitude}, ${_propertyLocation.longitude}');
      } catch (e) {
        print('Error adding property marker: $e');
        setState(() {
          _mapLoadError = true;
          _mapErrorMessage = 'Error adding marker: $e';
        });
      }

      // Initialize nearby places data for Satara
      _initializeNearbyPlacesForSatara();
    } catch (e) {
      print('Error in _initializeLocationData: $e');
      setState(() {
        _mapLoadError = true;
        _mapErrorMessage = 'Location initialization error: $e';
      });
    }
  }

  void _initializeNearbyPlacesForSatara() {
    final random = math.Random();

    // Satara landmarks and points of interest
    final sataraLandmarks = [
      {
        'type': 'Temple',
        'name': 'Bhairoba Temple',
        'latitude': 17.6843,
        'longitude': 74.0162,
        'distance': '0.7km',
      },
      {
        'type': 'Park',
        'name': 'Ajinkyatara Fort',
        'latitude': 17.6720,
        'longitude': 74.0007,
        'distance': '2.1km',
      },
      {
        'type': 'Shopping Mall',
        'name': 'Satara City Center',
        'latitude': 17.6856,
        'longitude': 74.0260,
        'distance': '1.1km',
      },
      {
        'type': 'Hospital',
        'name': 'Satara Civil Hospital',
        'latitude': 17.6867,
        'longitude': 74.0125,
        'distance': '0.9km',
      },
      {
        'type': 'School',
        'name': 'Satara Public School',
        'latitude': 17.6788,
        'longitude': 74.0225,
        'distance': '1.4km',
      },
      {
        'type': 'Restaurant',
        'name': 'Royal Restaurant',
        'latitude': 17.6810,
        'longitude': 74.0230,
        'distance': '0.6km',
      },
    ];

    // Randomly select 3-5 landmarks to show
    final placesToShow = [...sataraLandmarks];
    placesToShow.shuffle();
    final placesCount = math.min(3 + random.nextInt(3), placesToShow.length);

    _nearbyPlaces.clear();
    _nearbyPlaces.addAll(placesToShow.sublist(0, placesCount));

    // Add nearby place markers
    try {
      for (final place in _nearbyPlaces) {
        if (place['latitude'] != null && place['longitude'] != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('place_${place['name']}'),
              position: LatLng(
                  place['latitude'] as double, place['longitude'] as double),
              infoWindow: InfoWindow(
                title: place['name'] as String,
                snippet: '${place['type']} • ${place['distance']}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
            ),
          );
          print(
              'Added nearby place marker: ${place['name']} at ${place['latitude']}, ${place['longitude']}');
        }
      }
    } catch (e) {
      print('Error adding nearby place markers: $e');
    }
  }

  // Get approximate coordinates for a location
  _LocationData _getApproximateCoordinates(String location) {
    // Static map of locations to coordinates
    final locationMap = {
      'Jakarta': _LocationData(-6.2088, 106.8456),
      'Bali': _LocationData(-8.4095, 115.1889),
      'Pune': _LocationData(18.5204, 73.8567), // Pune, India
      'Maharashtra': _LocationData(19.7515, 75.7139),
      'India': _LocationData(20.5937, 78.9629),
    };

    // For Pune, return a random location within the city limits
    if (location.toLowerCase().contains('pune')) {
      final random = math.Random();
      final lat = 18.5204 + (random.nextDouble() - 0.5) * 0.05;
      final lng = 73.8567 + (random.nextDouble() - 0.5) * 0.05;
      return _LocationData(lat, lng);
    }

    // Try to find location in the map
    for (final entry in locationMap.entries) {
      if (location.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Default to Pune with a small random offset
    final random = math.Random();
    final lat =
        locationMap['Pune']!.latitude + (random.nextDouble() - 0.5) * 0.05;
    final lng =
        locationMap['Pune']!.longitude + (random.nextDouble() - 0.5) * 0.05;
    return _LocationData(lat, lng);
  }

  Future<void> _checkIfFavorited() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user != null && widget.property['id'] != null) {
      try {
        setState(() {
          isLoading = true;
        });

        final propertyId = widget.property['id'];

        // Check if property ID is a valid UUID
        if (!_isValidUuid(propertyId.toString())) {
          // If not a valid UUID, it might not be in favorites yet
          setState(() {
            isLoading = false;
            isFavorite = false;
          });
          return;
        }

        final response = await client
            .from('favorites')
            .select()
            .eq('user_id', user.id)
            .eq('property_id', propertyId)
            .maybeSingle();

        setState(() {
          isLoading = false;
          isFavorite = response != null;
        });
      } catch (e) {
        print('Error checking favorite status: $e');
        setState(() {
          isLoading = false;
        });
      }
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

  Future<void> _toggleFavorite() async {
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
            onPressed: () => Get.toNamed('/login'),
            textColor: const Color(0xFF988A44),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get the property ID and ensure it's valid
      final propertyId = widget.property['id'];

      if (propertyId == null) {
        throw Exception('Property ID is missing');
      }

      // Check if the property ID is a valid UUID or needs conversion
      String formattedPropertyId;

      if (!_isValidUuid(propertyId.toString())) {
        print(
            'Invalid UUID format: $propertyId, creating property in database first');

        // Create a new property entry with a valid UUID - only include fields defined in the schema
        final newProperty = {
          'title': widget.property['name'] ?? 'Property',
          'description':
              'Beautiful property in ${widget.property['location'] ?? 'Unknown location'}',
          'price': widget.property['price'] != null
              ? double.tryParse(widget.property['price']
                      .toString()
                      .replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0
              : 0,
          'city':
              widget.property['location']?.toString().split(',').first.trim() ??
                  'Unknown',
          'state': widget.property['location']?.toString().contains(',') == true
              ? widget.property['location'].toString().split(',').last.trim()
              : 'Unknown',
          'country': 'India',
          'address': widget.property['location'] ?? 'Address details',
          'zip_code': '411000',
          'property_type': widget.property['type'] ?? 'House',
          'bedrooms':
              int.tryParse(widget.property['bedrooms']?.toString() ?? '0') ?? 3,
          'bathrooms': double.tryParse(
                  widget.property['bathrooms']?.toString() ?? '0') ??
              2.0,
          'area': double.tryParse(widget.property['area']
                      ?.toString()
                      .replaceAll(RegExp(r'[^\d.]'), '') ??
                  '0') ??
              1200.0,
          'owner_id': user.id,
          'is_featured': false,
        };

        // Insert the property and get the UUID
        final propertyResponse = await client
            .from('properties')
            .insert(newProperty)
            .select('id')
            .single();

        formattedPropertyId = propertyResponse['id'];

        // Update the property in our widget
        widget.property['id'] = formattedPropertyId;

        // Now also add a property image if needed in the separate table
        if (widget.property['image_url'] != null) {
          try {
            await client.from('property_images').insert({
              'property_id': formattedPropertyId,
              'image_url': widget.property['image_url'],
              'is_primary': true,
            });
          } catch (imageError) {
            print('Could not insert property image: $imageError');
            // Continue with favorite toggle even if image insert fails
          }
        }

        print('Created property with UUID: $formattedPropertyId');
      } else {
        formattedPropertyId = propertyId.toString();
      }

      if (isFavorite) {
        // Remove from favorites
        await client.from('favorites').delete().match({
          'user_id': user.id,
          'property_id': formattedPropertyId,
        });
      } else {
        // Add to favorites
        await client.from('favorites').insert({
          'user_id': user.id,
          'property_id': formattedPropertyId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Show heart animation when added to favorites
        _showHeartAnimation();
      }

      setState(() {
        isFavorite = !isFavorite;
        isLoading = false;
      });

      // Show snackbar with action to view all likes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'Added to favorites' : 'Removed from favorites',
            style: GoogleFonts.raleway(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.white,
          action: isFavorite
              ? SnackBarAction(
                  label: 'View All',
                  onPressed: () {
                    // Navigate to favorites page
                    Get.toNamed('/favorites');
                  },
                  textColor: const Color(0xFF988A44),
                )
              : null,
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      setState(() {
        isLoading = false;
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

  // Show heart animation when property is liked
  void _showHeartAnimation() {
    // Declare the overlay entry variable first
    late OverlayEntry overlayEntry;

    // Define the overlay entry
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 3,
        left: MediaQuery.of(context).size.width / 2 - 50,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value > 0.8 ? 2 - value * 2 : value, // Fade in and out
              child: Transform.scale(
                scale: value * 2, // Grow and shrink
                child: Icon(
                  Icons.favorite,
                  color: Colors.red.withOpacity(0.8),
                  size: 100,
                ),
              ),
            );
          },
          onEnd: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(overlayEntry);
  }

  void _shareProperty() async {
    final name = widget.property['name'] ?? 'Property';
    final price = widget.property['price']?.toString() ?? '';
    final location = widget.property['location'] ?? '';
    final type = widget.property['type'] ?? 'Property';
    final bedrooms = widget.property['bedrooms']?.toString() ?? '0';
    final bathrooms = widget.property['bathrooms']?.toString() ?? '0';
    final area = widget.property['area']?.toString() ?? '0';

    // Create a detailed property message
    final message = '''
🏠 *Check out this amazing property!*

*Property Details:*
• Name: $name
• Type: $type
• Price: ₹$price
• Location: $location
• Features: $bedrooms beds, $bathrooms baths, $area sqft

Download our app to view more details and similar properties:
https://play.google.com/store/apps/details?id=com.best.realestate

#RealEstate #Property #HomeSearch
    ''';

    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(message);
    
    // Create WhatsApp URL
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encodedMessage');
    
    try {
      // Check if WhatsApp is installed
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // If WhatsApp is not installed, show a dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'WhatsApp Not Installed',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'WhatsApp is not installed on your device. Would you like to share through other means?',
                style: GoogleFonts.raleway(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.raleway(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Fallback to regular share
    Share.share(
      message,
      subject: 'Amazing Property: $name',
    );
                  },
                  child: Text(
                    'Share Anyway',
                    style: GoogleFonts.raleway(
                      color: const Color(0xFF988A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error sharing to WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing to WhatsApp: $e',
              style: GoogleFonts.raleway(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Track property inquiry for analytics
  void _trackPropertyInquiry(String propertyId) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      // If user is logged in, store inquiry in database
      if (user != null) {
        await client.from('property_inquiries').insert({
          'user_id': user.id,
          'property_id': propertyId,
          'inquiry_type': 'whatsapp',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // You could also implement logging to an analytics service here
    } catch (e) {
      // Silently handle error - don't interrupt the user experience
      print('Error tracking property inquiry: $e');
    }
  }

  // Method to edit the current property
  void _editProperty() async {
    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      // Get the current property data
      final propertyId = widget.property['id'];
      final response = await _supabase
          .from('properties')
          .select('*, property_photos(*)')
          .eq('id', propertyId)
          .single();

      if (response == null) {
        throw Exception('Property not found');
      }

      // Convert "Sell" to "Sale" in listing_type if needed
      if (response['listing_type'] == 'Sell') {
        response['listing_type'] = 'Sale';
      }

      // Navigate to edit page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPropertyPage(
            propertyId: propertyId,
            propertyData: response,
          ),
        ),
      );

      // If the edit was successful, refresh the property data
      if (result == true) {
        // Fetch updated property data
        final updatedProperty = await _supabase
            .from('properties')
            .select('*, property_photos(*)')
            .eq('id', propertyId)
            .single();

        if (updatedProperty != null) {
          // Update the property data with all fields
          setState(() {
            widget.property.addAll({
              'id': updatedProperty['id'] ?? '',
              'name': updatedProperty['title'] ?? 'Property',
              'location': updatedProperty['city'] ?? 'Unknown City',
              'price': updatedProperty['price'] != null ? '₹${updatedProperty['price']}' : 'Price on request',
              'type': updatedProperty['property_type'] ?? 'House',
              'bedrooms': updatedProperty['bedrooms']?.toString() ?? '0',
              'bathrooms': updatedProperty['bathrooms']?.toString() ?? '0',
              'area': updatedProperty['area'] != null ? '${updatedProperty['area']} sq.ft.' : 'Area not specified',
              'description': updatedProperty['description'] ?? '',
              'created_at': updatedProperty['created_at'] ?? DateTime.now().toIso8601String(),
              'image': updatedProperty['property_photos'] != null && 
                      updatedProperty['property_photos'].isNotEmpty
                  ? updatedProperty['property_photos'][0]['photo_url']
                  : 'assets/image1.jpg',
              // Add all the fields that are used in specifications section
              'property_type': updatedProperty['property_type'] ?? 'House',
              'year_built': updatedProperty['year_built']?.toString() ?? '2022',
              'bhk': updatedProperty['bhk'] ?? '3 BHK',
              'balconies': updatedProperty['balconies']?.toString() ?? '2',
              'city': updatedProperty['city'] ?? '',
              'state': updatedProperty['state'] ?? '',
              'country': updatedProperty['country'] ?? '',
              'address': updatedProperty['address'] ?? '',
              'special_status': updatedProperty['special_status'] ?? 'None',
            });
          });

          // Reload property photos
          await _loadPropertyPhotos();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Notify parent screens to refresh their data
          Navigator.pop(context, true); // Pop with refresh flag
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Method to delete the current property
  Future<void> _deleteProperty() async {
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

      setState(() {
        isLoading = true;
      });

      final propertyId = widget.property['id'];

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

      // Finally, delete the property
      await _supabase
          .from('properties')
          .delete()
          .eq('id', propertyId);

      setState(() {
        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to previous screen with refresh flag
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPropertyPhotos() async {
    try {
      setState(() {
        _isLoadingPhotos = true;
      });

      // First check if we have a valid property ID
      if (widget.property['id'] == null) {
        print('Property ID is null, cannot fetch photos');
        setState(() {
          _isLoadingPhotos = false;
        });
        return;
      }

      // Fetch property photos from Supabase using the correct table name
      final response = await _supabase
          .from('property_photos')
          .select('*')
          .eq('property_id', widget.property['id'])
          .order('photo_order', ascending: true);

      if (response != null && response.isNotEmpty) {
        print('Fetched ${response.length} property photos');
        setState(() {
          _propertyPhotos = List<Map<String, dynamic>>.from(response).map((photo) {
            return {
              'photo_url': photo['photo_url'],
              'photo_order': photo['photo_order'],
            };
          }).toList();
          _isLoadingPhotos = false;
        });
      } else {
        // If no photos found, try to use the property's main image
        print('No property photos found, using main image');
        if (widget.property['image'] != null) {
          setState(() {
            _propertyPhotos = [
              {
                'photo_url': widget.property['image'],
                'photo_order': 0,
              }
            ];
            _isLoadingPhotos = false;
          });
        } else {
          print('No images available for this property');
          setState(() {
            _propertyPhotos = [];
            _isLoadingPhotos = false;
          });
        }
      }
    } catch (e) {
      print('Error loading property photos: $e');
      setState(() {
        _isLoadingPhotos = false;
      });
    }
  }

  Widget _buildPropertyPhotosGallery() {
    if (_isLoadingPhotos) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C8500)),
      );
    }

    if (_propertyPhotos.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main image container
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              itemCount: _propertyPhotos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  _propertyPhotos[index]['photo_url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
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
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        // Thumbnail gallery
        Container(
          height: 80,
          margin: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _propertyPhotos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentImageIndex == index
                          ? const Color(0xFF7C8500)
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _propertyPhotos[index]['photo_url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
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
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _propertyPhotos.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? const Color(0xFF7C8500)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Like button for all users
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
              tooltip: 'Add to favorites',
            ),
          ),
          // Share button for all users
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareProperty,
              tooltip: 'Share property',
            ),
          ),
          // Admin buttons - only shown for admin users
          if (isAdmin) ...[
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _editProperty,
                tooltip: 'Edit property',
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteProperty,
                tooltip: 'Delete property',
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Images Section with fixed height
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildPropertyPhotosGallery(),
              ),
              
              // Property Details Section with proper padding
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPropertyHeader(),
                    const SizedBox(height: 24),
                    _buildPropertyFeatures(),
                    const SizedBox(height: 32),
                    _buildDescriptionSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Location'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 18, color: const Color(0xFF988A44)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.property['location'] ?? 'Location',
                                  style: GoogleFonts.raleway(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nearby Places: ${_nearbyPlaces.length} Points of Interest',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMapSection(),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nearby Places',
                                  style: GoogleFonts.raleway(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._nearbyPlaces.map((place) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForPlaceType(place['type']),
                                        size: 18,
                                        color: const Color(0xFF988A44),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${place['name']} (${place['distance']})',
                                          style: GoogleFonts.raleway(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Amenities'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _buildAmenitiesGrid(),
                    ),
                    const SizedBox(height: 32),
                    // Contact Buttons Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _shareProperty,
                              icon: const Icon(Icons.chat, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              label: Text(
                                'Contact via WhatsApp',
                                style: GoogleFonts.raleway(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    launchUrl(Uri.parse('tel:+917350530055'));
                                  },
                                  icon: const Icon(Icons.call, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF988A44),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  label: Text(
                                    'Call Agent',
                                    style: GoogleFonts.raleway(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Scheduling visit...'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.calendar_today,
                                      color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  label: Text(
                                    'Schedule Visit',
                                    style: GoogleFonts.raleway(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildPropertyHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Name with proper text wrapping
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.property['name'],
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Location Row with proper spacing
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.property['location'] ?? 'Location not specified',
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Price and Type Row
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Price
                Flexible(
                  child: Text(
                    '\$${widget.property['price']}/month',
                    style: GoogleFonts.raleway(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF988A44),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // Property Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF988A44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.property['type'] ?? 'Property',
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: const Color(0xFF988A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Property Status Badge
          Container(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Available',
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Features Grid in its own container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Features',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: [
                  _buildFeatureItem(Icons.bed, '${widget.property['bedrooms'] ?? 2} Beds'),
                  _buildFeatureItem(Icons.bathtub, '${widget.property['bathrooms'] ?? 1} Baths'),
                  _buildFeatureItem(Icons.square_foot, '${widget.property['area'] ?? 1200} sqft'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Specifications in its own container (reverted to original)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specifications',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildSpecItem('Type', widget.property['property_type'] ?? 'House'),
                  _buildSpecItem('Year Built', widget.property['year_built']?.toString() ?? '2022'),
                  _buildSpecItem('BHK', widget.property['bhk'] ?? '3 BHK'),
                  _buildSpecItem('Balconies', widget.property['balconies']?.toString() ?? '2'),
                  _buildSpecItem('Price', '₹${widget.property['price']?.toString() ?? '0'}'),
                  _buildSpecItem('Area', '${widget.property['area']?.toString() ?? '0'} sqft'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF988A44), size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    final amenities = [
      'Parking',
      'WiFi',
      'Swimming Pool',
      'Gym',
      'Air Conditioning',
      'Security'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF988A44), size: 18),
              const SizedBox(width: 8),
              Text(
                amenities[index],
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapSection() {
    return GestureDetector(
      onTap: () {
        _showFullScreenMap();
      },
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Use static map to avoid Google Maps widget errors
              _buildSimpleStaticMap(),

              // Add large Maps icon overlay in the center
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.map,
                    color: const Color(0xFF988A44),
                    size: 36,
                  ),
                ),
              ),

              // Add an overlay hint to indicate the map is tappable
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Satellite',
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add tap to expand hint
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to navigate',
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add address overlay
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: const Color(0xFF988A44), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Satara, Maharashtra',
                        style: GoogleFonts.raleway(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modify the _showFullScreenMap method to open external Google Maps with navigation
  void _showFullScreenMap() {
    // Open Google Maps in a browser with navigation option
    try {
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=Shop+No+3+%26+4+Powai+Naka+Satara&travelmode=driving';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show a full simple static map without gesture detector
  Widget _buildSimpleStaticMap() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _MapPainter(
                propertyLocation: _propertyLocation,
                nearbyPlaces: _nearbyPlaces),
            size: const Size(double.infinity, 250),
          ),
          // Map controls overlay
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop No 3 & 4, Powai Naka',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Satara, Maharashtra 415001',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add directions button
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton.small(
              heroTag: 'directions',
              backgroundColor: Colors.white,
              onPressed: _showFullScreenMap,
              child: const Icon(Icons.directions, color: Color(0xFF988A44)),
            ),
          ),
        ],
      ),
    );
  }

  // Update the description section to use admin's description
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Description'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.property['description'] ?? 'No description available',
            style: GoogleFonts.raleway(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _checkAdminRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        
        setState(() {
          isAdmin = response['role'] == 'admin';
        });
      }
    } catch (e) {
      print('Error checking admin role: $e');
      setState(() {
        isAdmin = false;
      });
    }
  }
}

// Update the _MapPainter class to show a satellite-style view
class _MapPainter extends CustomPainter {
  final LatLng propertyLocation;
  final List<Map<String, dynamic>> nearbyPlaces;

  _MapPainter({required this.propertyLocation, required this.nearbyPlaces});

  @override
  void paint(Canvas canvas, Size size) {
    // Basic map styling
    final paint = Paint();

    // Light background for map
    paint.color = const Color(0xFFF0F0F0);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw grid lines for map
    paint.color = const Color(0xFFE0E0E0);
    paint.strokeWidth = 1;

    // Grid lines
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw main road
    paint.color = const Color(0xFFD0D0D0);
    paint.strokeWidth = 8;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
      paint,
    );

    // Draw secondary road
    paint.strokeWidth = 6;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      paint,
    );

    // Draw property marker
    paint.color = const Color(0xFF988A44);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      10,
      paint,
    );

    // Draw border around property marker
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      10,
      borderPaint,
    );

    // Draw nearby places
    final nearbyPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Generate nearby place positions
    final random = math.Random(42); // Fixed seed for consistency
    for (int i = 0; i < math.min(nearbyPlaces.length, 3); i++) {
      final dx = random.nextDouble() * 0.3 + 0.2; // Between 0.2 and 0.5
      final dy = random.nextDouble() * 0.3 + 0.2; // Between 0.2 and 0.5

      final x = i == 0
          ? size.width * dx
          : (i == 1 ? size.width * (1 - dx) : size.width * 0.8);
      final y = i == 0
          ? size.height * dy
          : (i == 1 ? size.height * (1 - dy) : size.height * 0.3);

      canvas.drawCircle(
        Offset(x, y),
        6,
        nearbyPaint,
      );
    }

    // Draw compass
    final compassCenter = Offset(size.width * 0.9, size.height * 0.1);
    final compassRadius = 15.0;

    // Draw compass circle
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(compassCenter, compassRadius, paint);

    // Draw compass border
    paint.color = Colors.grey;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawCircle(compassCenter, compassRadius, paint);

    // Draw N indicator
    paint.color = const Color(0xFF988A44);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(compassCenter.dx, compassCenter.dy - compassRadius * 0.7)
        ..lineTo(compassCenter.dx - compassRadius * 0.3, compassCenter.dy)
        ..lineTo(compassCenter.dx + compassRadius * 0.3, compassCenter.dy)
        ..close(),
      paint,
    );

    // Draw text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        compassCenter.dx - textPainter.width / 2,
        compassCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add this new class at the end of the file (outside the PropertyDetailsPageState class)
class FullScreenMapPage extends StatefulWidget {
  final LatLng propertyLocation;
  final String propertyName;
  final String propertyAddress;
  final List<Map<String, dynamic>> nearbyPlaces;

  const FullScreenMapPage({
    Key? key,
    required this.propertyLocation,
    required this.propertyName,
    required this.propertyAddress,
    required this.nearbyPlaces,
  }) : super(key: key);

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  GoogleMapController? _mapController;
  bool _showNearbyPlaces = true;
  bool _showTraffic = false;
  Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    // Create a set with the main property marker
    final Set<Marker> markers = {};

    // Add property marker
    markers.add(
      Marker(
        markerId: const MarkerId('property'),
        position: widget.propertyLocation,
        infoWindow: InfoWindow(
          title: widget.propertyName,
          snippet: widget.propertyAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add nearby place markers if they have coordinates
    if (_showNearbyPlaces) {
      for (final place in widget.nearbyPlaces) {
        if (place['latitude'] != null && place['longitude'] != null) {
          markers.add(
            Marker(
              markerId: MarkerId('place_${place['name']}'),
              position: LatLng(
                place['latitude'] as double,
                place['longitude'] as double,
              ),
              infoWindow: InfoWindow(
                title: place['name'] as String,
                snippet: '${place['type']} • ${place['distance']}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _setMapStyle(GoogleMapController controller) async {
    if (controller == null) {
      print('Cannot set map style: controller is null');
      return;
    }

    try {
      // Light style that matches the app's aesthetics
      const String mapStyle = '''
      [
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "poi",
          "stylers": [
            {
              "visibility": "simplified"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.icon",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "transit",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        }
      ]
      ''';

      // Only apply style in normal map mode, use empty style for satellite
      if (_currentMapType == MapType.normal) {
        await controller.setMapStyle(mapStyle);
      } else {
        await controller.setMapStyle('');
      }
    } catch (e) {
      print('Error applying map style: $e');
    }
  }

  void _toggleNearbyPlaces() {
    setState(() {
      _showNearbyPlaces = !_showNearbyPlaces;
      _initializeMarkers();
    });
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
      if (_mapController != null) {
        _setMapStyle(_mapController!);
      }
    });
  }

  void _toggleTraffic() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.propertyName, style: const TextStyle(fontSize: 16)),
            Text(
              widget.propertyAddress,
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF988A44),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showNearbyPlaces ? Icons.place : Icons.place_outlined),
            onPressed: _toggleNearbyPlaces,
            tooltip: 'Toggle nearby places',
          ),
          IconButton(
            icon: Icon(_currentMapType == MapType.normal
                ? Icons.map
                : Icons.satellite_alt),
            onPressed: _toggleMapType,
            tooltip: 'Change map type',
          ),
          IconButton(
            icon: Icon(_showTraffic ? Icons.traffic : Icons.traffic_outlined),
            onPressed: _toggleTraffic,
            tooltip: 'Show traffic',
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.propertyLocation,
          zoom: 15.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            _mapController = controller;
          });
          _setMapStyle(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
        compassEnabled: true,
        trafficEnabled: _showTraffic,
        mapType: _currentMapType,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: widget.propertyLocation,
                  zoom: 16.0,
                  tilt: 45.0,
                ),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFF988A44),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}

// Add this new class at the end of the file (outside all other classes)
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    required this.tag,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // If zoomed in, zoom out
      _transformationController.value = Matrix4.identity();
    } else {
      // If zoomed out, zoom in
      if (_doubleTapDetails != null) {
        final position = _doubleTapDetails!.localPosition;
        // Zoom to the point that was double-tapped
        final Matrix4 newMatrix = Matrix4.identity()
          ..translate(-position.dx * 2, -position.dy * 2)
          ..scale(3.0);
        _transformationController.value = newMatrix;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: widget.tag,
              child: Image.asset(
                'assets/image1.jpg',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Add a new image gallery class
class PropertyImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PropertyImageGallery({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<PropertyImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Photo ${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share the current image
              Share.share('Check out this amazing property!');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main image page view
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 300) {
                    Navigator.pop(context);
                  }
                },
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: index == 0
                          ? widget.images[index]
                          : '${widget.images[index]}_thumb_$index',
                      child: Image.asset(
                        'assets/image1.jpg',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[900],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.white, size: 60),
                                SizedBox(height: 16),
                                Text(
                                  'Image could not be loaded',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Thumbnails at the bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentIndex == index
                                  ? Colors.white
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.asset(
                                'assets/image1.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white, size: 24),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Page indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? const Color(0xFF988A44)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
