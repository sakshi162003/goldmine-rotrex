import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'information.dart';
import 'success_page.dart';

/// Add Photos Page
class AddPhotosPage extends StatefulWidget {
  final String listingType;
  final String propertyId;

  const AddPhotosPage({
    Key? key,
    required this.listingType,
    required this.propertyId,
  }) : super(key: key);

  @override
  _AddPhotosPageState createState() => _AddPhotosPageState();
}

class _AddPhotosPageState extends State<AddPhotosPage> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = '${widget.propertyId}_${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(file.path)}';
        
        try {
          print('Starting upload for image $i');
          print('File name: $fileName');
          
          // Read the file as bytes
          final bytes = await file.readAsBytes();
          print('File bytes read: ${bytes.length} bytes');
          
          // Upload image to Supabase Storage
          print('Uploading to storage...');
          await _supabase.storage
              .from('properties')
              .uploadBinary(fileName, bytes, fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true
              ));
          print('Upload successful');

          // Get the public URL
          final imageUrl = _supabase.storage
              .from('properties')
              .getPublicUrl(fileName);
          print('Image URL: $imageUrl');

          // Save to property_photos table with photo_order
          print('Attempting to save to database...');
          final response = await _supabase
              .from('property_photos')
              .insert({
                'property_id': widget.propertyId,
                'photo_url': imageUrl,  // Store the full public URL
                'photo_order': i + 1,  // 1-based index for photo order
              })
              .select();
          
          print('Database response: $response');

        } catch (uploadError) {
          print('Error in upload process: $uploadError');
          continue;
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInformationPage(
              listingType: widget.listingType,
              propertyId: widget.propertyId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Overall error: $e');
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      // For web platform, use Image.network with the file path
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // For mobile platforms, use Image.file
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
    );
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
          'Add Photos',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Property Photos',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload at least one photo of your property',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey.shade400,
                          ),
                            const SizedBox(height: 8),
                          Text(
                              'Add Photos',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                          ),
                        ],
                      ),
                      ),
                    );
                  }
                        return Stack(
                          children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildImagePreview(_selectedImages[index - 1]),
                            ),
                            Positioned(
                        top: 5,
                        right: 5,
                              child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index - 1);
                            });
                          },
                                child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8C100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
