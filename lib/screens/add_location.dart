import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'information.dart';
import 'add_photos_page.dart';

/// Add Location Page
class AddLocationPage extends StatefulWidget {
  final String listingType;
  final String propertyName;
  final String propertyType;
  final String description;
  final String specialStatus;
  
  const AddLocationPage({
    Key? key, 
    required this.listingType,
    required this.propertyName,
    required this.propertyType,
    required this.description,
    required this.specialStatus,
  }) : super(key: key);
  
  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _supabase = Supabase.instance.client;
  // Replace single controller with multiple controllers for detailed address fields
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController(text: "Maharashtra");
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "India");
  // Add a list to hold city suggestions
  List<String> _citySuggestions = [];
  bool _isLoadingCities = false;

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create property data
      final propertyData = {
        'title': widget.propertyName,
        'description': widget.description,
        'property_type': widget.propertyType,
        'listing_type': widget.listingType,
        'address': _streetController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postal_code': _postalCodeController.text,
        'country': _countryController.text,
        'created_by': user.id,
        'is_active': true,
        'is_featured': false,
        'special_status': widget.specialStatus == 'None' ? null : widget.specialStatus,
      };

      // Insert property into database
      final response = await _supabase
          .from('properties')
          .insert(propertyData)
          .select('id')
          .single();

      // Navigate to next page with property ID
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPhotosPage(
              listingType: widget.listingType,
              propertyId: response['id'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving property: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onNextPressed() {
    // Check which required fields are empty
    List<String> emptyFields = [];

    if (_streetController.text.trim().isEmpty) {
      emptyFields.add('Street Address');
    }

    if (_cityController.text.trim().isEmpty) {
      emptyFields.add('City');
    }

    if (_postalCodeController.text.trim().isEmpty) {
      emptyFields.add('Postal Code');
    }

    // If any required fields are empty, show the dialog
    if (emptyFields.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8C100).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB8C100),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Missing Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please fill in the following required fields:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // List of empty fields
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8C100).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: emptyFields
                          .map((field) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Color(0xFFB8C100),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      field,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8C100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // All required fields are filled, save property and proceed to next page
      _saveProperty();
    }
  }

  // Fetch distinct cities from the database based on input
  Future<void> _fetchCitySuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _citySuggestions = []);
      return;
    }
    setState(() => _isLoadingCities = true);
    final response = await _supabase
        .from('properties')
        .select('city')
        .ilike('city', '%$input%');
    final cities = response
        .map<String>((item) => (item['city'] ?? '').toString())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      _citySuggestions = cities;
      _isLoadingCities = false;
    });
  }

  // Custom input field builder for reusability
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text(
                  hintText + (isRequired ? ' *' : ''),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  ' (Required)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                prefixIcon:
                    Icon(icon, color: const Color(0xFFB8C100), size: 24),
                filled: true,
                fillColor: Colors.grey.shade100,
                hintText: 'Enter $hintText',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: const Color(0xFFB8C100), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
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
          'Add Listing',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 22, color: Colors.black),
                children: [
                  TextSpan(text: 'Where is the '),
                  TextSpan(
                    text: 'location?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB8C100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Let\'s add the perfect location for your property',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Detailed address form in a scrollable container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _streetController,
                        hintText: 'Street Address',
                        icon: Icons.home_outlined,
                        isRequired: true,
                        maxLines: 2,
                      ),
                      // Replace city field with Autocomplete
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                  child: Text(
                                    'City *',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' (Required)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue textEditingValue) async {
                                  await _fetchCitySuggestions(textEditingValue.text);
                                  return _citySuggestions.where((city) => city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                },
                                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                  controller.text = _cityController.text;
                                  controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onChanged: (value) {
                                      _cityController.text = value;
                                      _fetchCitySuggestions(value);
                                    },
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.location_city_outlined, color: Color(0xFFB8C100), size: 24),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      hintText: 'Enter City',
                                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(color: Color(0xFFB8C100), width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    ),
                                  );
                                },
                                onSelected: (String selection) {
                                  _cityController.text = selection;
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.7,
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (context, index) {
                                            final option = options.elementAt(index);
                                            return ListTile(
                                              title: Text(option, style: GoogleFonts.poppins(fontSize: 14)),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _stateController,
                              hintText: 'State/Province',
                              icon: Icons.map_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _postalCodeController,
                              hintText: 'Postal Code',
                              icon: Icons.pin_outlined,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        controller: _countryController,
                        hintText: 'Country',
                        icon: Icons.public,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      child: const Icon(Icons.arrow_back,
                          color: Colors.black, size: 28),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC1D000), Color(0xFF7A8900)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB8C100).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _onNextPressed,
                      child: Text('Next',
                          style: GoogleFonts.poppins(
                              fontSize: 18, color: Colors.white)),
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
}
