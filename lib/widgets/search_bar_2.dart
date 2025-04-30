import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageSearchScreen(),
    );
  }
}

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => ImageSearchScreenState();
}

class ImageSearchScreenState extends State<ImageSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> allImages = [
    {"location": "New York", "image": "https://via.placeholder.com/150"},
    {"location": "London", "image": "https://via.placeholder.com/150"},
    {"location": "Tokyo", "image": "https://via.placeholder.com/150"},
    {"location": "Paris", "image": "https://via.placeholder.com/150"},
  ];

  List<Map<String, String>> filteredImages = [];

  @override
  void initState() {
    super.initState();
    filteredImages = allImages;
  }

  void _search() {
    String query = _controller.text.toLowerCase();
    setState(() {
      filteredImages = allImages
          .where((img) => img['location']!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Image Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomSearchBar(
              controller: _controller,
              onChanged: _search,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredImages.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(filteredImages[index]['location']!,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Image.network(filteredImages[index]['image']!),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Search for properties...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF988A44)),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
