import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:best/presentation/controllers/auth_controller.dart';

class EditPropertyPage extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const EditPropertyPage({
    super.key,
    required this.propertyId,
    required this.propertyData,
  });

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _areaController;

  String _selectedListingType = 'Rent';
  String _selectedCategory = 'House';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkAdminStatus();
  }

  void _initializeControllers() {
    // Initialize controllers with existing data
    _nameController =
        TextEditingController(text: widget.propertyData['name'] ?? '');
    _priceController = TextEditingController(
        text: widget.propertyData['price']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.propertyData['description'] ?? '');
    _addressController =
        TextEditingController(text: widget.propertyData['address'] ?? '');
    _bedroomsController = TextEditingController(
        text: widget.propertyData['bedrooms']?.toString() ?? '');
    _bathroomsController = TextEditingController(
        text: widget.propertyData['bathrooms']?.toString() ?? '');
    _areaController = TextEditingController(
        text: widget.propertyData['area']?.toString() ?? '');

    // Set listing type and category if available
    _selectedListingType = widget.propertyData['listing_type'] ?? 'Rent';
    _selectedCategory = widget.propertyData['category'] ?? 'House';
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    await _authController.verifyAdminStatus();
    if (!_authController.isAdmin.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveProperty() async {
    // Validate inputs
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and price are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      // Parse numeric values
      final int? bedrooms = int.tryParse(_bedroomsController.text);
      final int? bathrooms = int.tryParse(_bathroomsController.text);
      final int? area = int.tryParse(_areaController.text);
      final double? price = double.tryParse(_priceController.text);

      // Update property data
      await _supabase.from('properties').update({
        'name': _nameController.text,
        'price': price,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area': area,
        'listing_type': _selectedListingType,
        'category': _selectedCategory,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.propertyId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
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
          'Edit Property',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB8C100)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Name
              _buildSectionTitle('Property Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter property name',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 24),

              // Price
              _buildSectionTitle('Price'),
              _buildTextField(
                controller: _priceController,
                hintText: 'Enter price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Listing Type
              _buildSectionTitle('Listing Type'),
              Row(
                children: ['Rent', 'Sell'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      label: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedListingType == type
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      selected: _selectedListingType == type,
                      selectedColor: const Color(0xFFB8C100),
                      backgroundColor: Colors.grey.shade300,
                      onSelected: (selected) {
                        setState(() => _selectedListingType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Property Category
              _buildSectionTitle('Property Category'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['House', 'Apartment', 'Hotel', 'Villa', 'Cottage']
                    .map((category) {
                  return ChoiceChip(
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    label: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedCategory == category
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    selected: _selectedCategory == category,
                    selectedColor: const Color(0xFFB8C100),
                    backgroundColor: Colors.grey.shade300,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Enter property description',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Address
              _buildSectionTitle('Address'),
              _buildTextField(
                controller: _addressController,
                hintText: 'Enter property address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Property Details (Bedrooms, Bathrooms, Area)
              _buildSectionTitle('Property Details'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _bedroomsController,
                      hintText: 'Bedrooms',
                      icon: Icons.bed_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _bathroomsController,
                      hintText: 'Bathrooms',
                      icon: Icons.bathtub_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _areaController,
                hintText: 'Area (sqft)',
                icon: Icons.square_foot_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8C100),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade700),
        contentPadding: EdgeInsets.symmetric(
          vertical: maxLines > 1 ? 16 : 0,
          horizontal: 16,
        ),
      ),
    );
  }
}
