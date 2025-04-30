import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewToggle extends StatelessWidget {
  final bool isGridView;
  final int itemCount;
  final Function(bool) onToggle;

  const ViewToggle({super.key, required this.isGridView, required this.itemCount, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Found $itemCount estates',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: const Color(0xFF988A44)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.grid_view, color: isGridView ? const Color(0xFF988A44) : Colors.grey),
                onPressed: () => onToggle(true),
              ),
              IconButton(
                icon: Icon(Icons.list, color: !isGridView ? const Color(0xFF988A44) : Colors.grey),
                onPressed: () => onToggle(false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


