import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_page.dart';

class AddInformationPage extends StatefulWidget {
  final String listingType;
  final String propertyId;
  
  const AddInformationPage({
    Key? key, 
    required this.listingType,
    required this.propertyId,
  }) : super(key: key);
  
  @override
  _AddInformationPageState createState() => _AddInformationPageState();
}

class _AddInformationPageState extends State<AddInformationPage> {
  final _supabase = Supabase.instance.client;
  int bedrooms = 3;
  int bathrooms = 2;
  int balconies = 2;
  String selectedBhk = "2BHK"; // Default selected BHK
  bool isMonthly = true;
  int area = 0;
  int yearBuilt = 2023;

  TextEditingController sellPriceController = TextEditingController(text: "0");
  TextEditingController rentPriceController = TextEditingController(text: "0");
  TextEditingController areaController = TextEditingController(text: "0");
  TextEditingController yearBuiltController = TextEditingController(text: "2023");
  TextEditingController additionalFeaturesController = TextEditingController();

  final List<String> facilities = [
    "Parking Lot",
    "Pet Allowed",
    "Garden",
    "Gym",
    "Park",
    "Home Theatre",
    "Kid's Friendly"
  ];

  final List<String> bhkOptions = ["1BHK", "2BHK", "3BHK", "4BHK"];

  final Set<String> selectedFacilities = {"Parking Lot", "Garden", "Gym"};

  @override
  void dispose() {
    sellPriceController.dispose();
    rentPriceController.dispose();
    areaController.dispose();
    yearBuiltController.dispose();
    additionalFeaturesController.dispose();
    super.dispose();
  }

  void toggleFacility(String facility) {
    setState(() {
      if (selectedFacilities.contains(facility)) {
        selectedFacilities.remove(facility);
      } else {
        selectedFacilities.add(facility);
      }
    });
  }

  Future<void> _saveAdditionalInfo() async {
    try {
      // Parse numeric values
      final price = widget.listingType == 'Rent' 
          ? double.tryParse(rentPriceController.text) ?? 0
          : double.tryParse(sellPriceController.text) ?? 0;
      
      final area = double.tryParse(areaController.text) ?? 0;
      final yearBuilt = int.tryParse(yearBuiltController.text) ?? 2023;

      // Update property with additional information
      await _supabase.from('properties').update({
        'price': price,
        'area': area,
        'year_built': yearBuilt,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'balconies': balconies,
        'bhk': selectedBhk,
        'facilities': selectedFacilities.toList(),
        'additional_features': additionalFeaturesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.propertyId);

      if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SuccessPage()),
    );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving property information: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFinishPressed() {
    _saveAdditionalInfo();
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
          'Additional Information',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Details',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Price Section
            Text(
              'Price',
                  style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
              const SizedBox(height: 10),
            if (widget.listingType == 'Rent')
              TextField(
                controller: rentPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter monthly rent',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
                ),
              )
            else
              TextField(
                controller: sellPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter selling price',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
              ),
              ),
            const SizedBox(height: 20),

            // Area Section
            Text(
              'Area (sq ft)',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: areaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter area in square feet',
                prefixIcon: const Icon(Icons.aspect_ratio),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Year Built Section
            Text(
              'Year Built',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: yearBuiltController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter year built',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rooms Section
            Text(
              'Rooms',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Bedrooms'),
                      DropdownButton<int>(
                        value: bedrooms,
                        items: List.generate(6, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => bedrooms = value!);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Bathrooms'),
                      DropdownButton<int>(
                        value: bathrooms,
                        items: List.generate(5, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => bathrooms = value!);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Balconies'),
                      DropdownButton<int>(
                        value: balconies,
                        items: List.generate(4, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => balconies = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // BHK Section
            Text(
              'BHK Type',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: bhkOptions.map((bhk) {
                return ChoiceChip(
                  label: Text(bhk),
                  selected: selectedBhk == bhk,
                  onSelected: (selected) {
                    setState(() => selectedBhk = bhk);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Facilities Section
            Text(
              'Facilities',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: facilities.map((facility) {
                return FilterChip(
                  label: Text(facility),
                  selected: selectedFacilities.contains(facility),
                  onSelected: (selected) => toggleFacility(facility),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Additional Features Section
            Text(
              'Additional Features',
                style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: additionalFeaturesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter any additional features',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Finish Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onFinishPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8C100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Finish',
                        style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
