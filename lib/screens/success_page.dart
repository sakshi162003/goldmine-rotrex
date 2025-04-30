import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; // Import the home page
import 'add_listing_page.dart'; // Import the add listing page

class SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Blurred Background
          Container(color: Colors.black.withOpacity(0.1)),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.5,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Success Icon
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.green.shade600, Colors.green.shade300],
                        ),
                      ),
                      padding: const EdgeInsets.all(15),
                      child: const Icon(Icons.check, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 20),

                    // Success Message
                    Text(
                      "Your listing is now",
                      style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87),
                    ),
                    Text(
                      "published",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      "Your property listing has been successfully published.",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(context, "Add More", Colors.grey.shade200, Colors.black, () {
                          // Navigate back to Add Listing Page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => AddListingPage()),
                            (route) => false, // Clear navigation stack
                          );
                        }),
                        _buildButton(context, "Finish", Colors.yellow.shade700, Colors.white, () {
                          // Navigate back to Home Page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()), 
                            (route) => false, // Clear navigation stack
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(text, style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
    );
  }
}
