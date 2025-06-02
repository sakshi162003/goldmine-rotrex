import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/presentation/controllers/auth_controller.dart';

class EditPropertyPage extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const EditPropertyPage({
    Key? key,
    required this.propertyId,
    required this.propertyData,
  }) : super(key: key);

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool isLoading = false;

  // Controllers for form fields
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController areaController;
  late TextEditingController yearBuiltController;
  late TextEditingController bedroomsController;
  late TextEditingController bathroomsController;
  late TextEditingController balconiesController;
  late TextEditingController bhkController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController countryController;
  late TextEditingController addressController;

  String selectedPropertyType = 'House';
  String selectedListingType = 'Sale';
  String selectedSpecialStatus = 'None';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    titleController = TextEditingController(text: widget.propertyData['title']);
    descriptionController = TextEditingController(text: widget.propertyData['description']);
    priceController = TextEditingController(text: widget.propertyData['price']?.toString());
    areaController = TextEditingController(text: widget.propertyData['area']?.toString());
    yearBuiltController = TextEditingController(text: widget.propertyData['year_built']?.toString());
    bedroomsController = TextEditingController(text: widget.propertyData['bedrooms']?.toString());
    bathroomsController = TextEditingController(text: widget.propertyData['bathrooms']?.toString());
    balconiesController = TextEditingController(text: widget.propertyData['balconies']?.toString());
    bhkController = TextEditingController(text: widget.propertyData['bhk']);
    cityController = TextEditingController(text: widget.propertyData['city'] ?? '');
    stateController = TextEditingController(text: widget.propertyData['state'] ?? '');
    countryController = TextEditingController(text: widget.propertyData['country'] ?? '');
    addressController = TextEditingController(text: widget.propertyData['address'] ?? '');
    selectedSpecialStatus = widget.propertyData['special_status'] ?? 'None';
    
    // Convert "Sell" to "Sale" if needed
    String listingType = widget.propertyData['listing_type'] ?? 'Sale';
    selectedListingType = listingType == 'Sell' ? 'Sale' : listingType;

    // Print debug information
    print('Initializing with listing type: ${widget.propertyData['listing_type']} (converted to: $selectedListingType)');
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    areaController.dispose();
    yearBuiltController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    balconiesController.dispose();
    bhkController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final updates = {
        'title': titleController.text,
        'description': descriptionController.text,
        'property_type': selectedPropertyType,
        'listing_type': selectedListingType,
        'price': double.tryParse(priceController.text),
        'area': double.tryParse(areaController.text),
        'year_built': int.tryParse(yearBuiltController.text),
        'bedrooms': int.tryParse(bedroomsController.text),
        'bathrooms': int.tryParse(bathroomsController.text),
        'balconies': int.tryParse(balconiesController.text),
        'bhk': bhkController.text,
        'city': cityController.text,
        'state': stateController.text,
        'country': countryController.text,
        'address': addressController.text,
        'special_status': selectedSpecialStatus == 'None' ? null : selectedSpecialStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('properties')
          .update(updates)
          .eq('id', widget.propertyId);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      }
    } finally {
      if (mounted) {
      setState(() {
          isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Property',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveChanges,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Property',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Update the details of your property below.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: titleController,
                                label: 'Title',
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter a title' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: descriptionController,
                                label: 'Description',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: addressController,
                                label: 'Address',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: cityController,
                                label: 'City',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: stateController,
                                label: 'State',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: countryController,
                                label: 'Country',
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                value: selectedSpecialStatus,
                                label: 'Special Status',
                                items: ['None', 'Offer', 'Special offer', 'New Land'],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedSpecialStatus = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                value: selectedPropertyType,
                                label: 'Property Type',
                                items: ['House', 'Apartment', 'Villa', 'Commercial'],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedPropertyType = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                value: selectedListingType,
                                label: 'Listing Type',
                                items: ['Sale', 'Rent'],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedListingType = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: priceController,
                                label: 'Price',
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter a price' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: areaController,
                                label: 'Area (sq ft)',
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter an area' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: yearBuiltController,
                                label: 'Year Built',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: bedroomsController,
                                label: 'Bedrooms',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: bathroomsController,
                                label: 'Bathrooms',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: balconiesController,
                                label: 'Balconies',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: bhkController,
                                label: 'BHK',
                              ),
                            ],
                          ),
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
                            child: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
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
                                color: Color(0xFFB8C100).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: isLoading ? null : _saveChanges,
                            child: Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
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
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                hintText: 'Enter $label',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: const Color(0xFFB8C100), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
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
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: const Color(0xFFB8C100), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
