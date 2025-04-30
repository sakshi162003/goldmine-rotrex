import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:best/screens/property_detail.dart';
//import '../property_details.dart';

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final int index;
  final bool isGrid;
  final VoidCallback onToggleFavorite;

  const PropertyCard({
    super.key,
    required this.property,
    required this.index,
    required this.isGrid,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final imageHeight = isGrid ? screenWidth * 0.55 : screenWidth * 0.4;
          final imageWidth = isGrid ? screenWidth : screenWidth * 0.38;

          final priceFont = screenWidth * (isGrid ? 0.045 : 0.038);
          final titleFont = screenWidth * (isGrid ? 0.050 : 0.045);
          final subtitleFont = screenWidth * (isGrid ? 0.040 : 0.034);

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: isGrid
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.asset(
                          'assets/image1.jpg',
                          height: imageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _buildDetails(priceFont, titleFont, subtitleFont, 8),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16)),
                        child: Image.asset(
                          'assets/image1.jpg',
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: _buildDetails(
                            priceFont, titleFont, subtitleFont, 12),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDetails(
      double priceFont, double titleFont, double subtitleFont, double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${property['price']}/month',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: priceFont,
              color: const Color(0xFF988A44),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            property['name'],
            style: GoogleFonts.raleway(
              fontSize: titleFont,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            property['location'],
            style: GoogleFonts.raleway(
              fontSize: subtitleFont,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
