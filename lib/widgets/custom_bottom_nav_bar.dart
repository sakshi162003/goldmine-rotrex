import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6), // Reduced bottom distance
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 0, isLarge: true),
          _buildNavItem(Icons.search_outlined, 1, isLarge: true),
          _buildNavItem(Icons.favorite_border, 2),
          _buildNavItem(Icons.person_outline, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, {bool isLarge = false}) {
    bool isSelected = selectedIndex == index;

    double iconSize = isLarge ? 29 : 28; // Home & Search are 1 unit larger
    double containerWidth = isLarge ? 31 : 30; // Adjust width
    double containerHeight = isLarge ? 35 : 34; // Adjust height

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerWidth,
            height: containerHeight,
            alignment: Alignment.center, // Centers the icon
            child: Icon(
              icon,
              size: iconSize,
              color: isSelected ? Colors.blue.shade900 : const Color(0xFF988A44), // Golden brown outline
            ),
          ),
          const SizedBox(height: 3), // Space between icon and dot
          if (isSelected)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.amber.shade700, // Golden dot
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
