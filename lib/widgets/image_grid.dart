import 'package:flutter/material.dart';

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          buildImage('assets/image1.jpg'),
          buildImage('assets/image1.jpg'),
          buildImage('assets/image1.jpg'),
          buildImage('assets/image1.jpg'),
        ],
      ),
    );
  }

  Widget buildImage(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
      ),
    );
  }
}
