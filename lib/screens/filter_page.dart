import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterPage extends StatefulWidget {
  final String initialLocation;
  final String initialType;
  final Function(Map<String, dynamic>) onApply;

  const FilterPage({
    super.key,
    required this.initialLocation,
    required this.initialType,
    required this.onApply,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String? _selectedLocation;
  late String _selectedType;

  final List<String> locations = [
    'Kharadi, Pune',
    'Vimannagar, Pune',
    'Hadapsar, Pune',
    'Bali, Indonesia',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation.isEmpty ? null : widget.initialLocation;
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Filter',
          style: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7C8500),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7C8500)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            child: Text(
              'Reset',
              style: GoogleFonts.raleway(color: const Color(0xFF7C8500)),
            ),
            onPressed: () {
              setState(() {
                _selectedLocation = null;
                _selectedType = 'All';
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property type',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C8500),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'House', 'Apartment', 'Land'].map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedType == type,
                  selectedColor: const Color(0xFF7C8500).withOpacity(0.2),
                  onSelected: (selected) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Location',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C8500),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select Location'),
                ),
                ...locations.map((location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLocation = value),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C8500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  widget.onApply({
                    'location': _selectedLocation ?? '',
                    'propertyType': _selectedType,
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Apply Filter',
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
