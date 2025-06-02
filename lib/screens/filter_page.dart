import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoadingLocations = true;
  List<String> _locations = [];
  final _supabase = Supabase.instance.client;

  final List<String> propertyTypes = [
    'All',
    'House',
    'Apartment',
    'Villa',
    'Land',
    'Commercial'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation.isEmpty ? null : widget.initialLocation;
    _selectedType = widget.initialType;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      // Fetch distinct cities from the properties table
      final response = await _supabase
          .from('properties')
          .select('city')
          .not('city', 'is', null)
          .execute();

      if (response.data != null) {
        // Extract unique cities and sort them
        final Set<String> uniqueCities = {};
        for (var row in response.data) {
          if (row['city'] != null && row['city'].toString().isNotEmpty) {
            uniqueCities.add(row['city'].toString());
          }
        }

        setState(() {
          _locations = uniqueCities.toList()..sort();
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedType = 'All';
    });
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
            onPressed: _resetFilters,
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
              children: propertyTypes.map((type) {
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
            _isLoadingLocations
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C8500),
                    ),
                  )
                : DropdownButtonFormField<String>(
              value: _selectedLocation,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                      hintText: 'Select Location',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                        child: Text('All Locations'),
                ),
                      ..._locations.map((location) => DropdownMenuItem(
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
