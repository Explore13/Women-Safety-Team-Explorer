import 'package:flutter/material.dart';

class CustomAppbar extends StatelessWidget {
  CustomAppbar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background with Curved Top
        ClipPath(
          clipper: InvertedCurvedClipper(), // Custom inverted curved shape
          child: Container(
            height: 160, // Extended height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 239, 123, 217), // Dark purple
            Color.fromARGB(255, 239, 123, 217),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 237, 5, 202),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),

        // AppBar Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 20, // Adjust for notch
          left: 20,
          child: Row(
            children: [
              // App Icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_rounded, // Updated icon
                  size: 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12), // Spacing

              // App Name with New Font
              Text(
                "Surakhsha",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins', // Changed font to Poppins
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black38,
                      offset: Offset(1, 2),
                    ),
                  ],
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom ClipPath for **Inverted Curved** Effect
class InvertedCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20); // Start from bottom left
    path.quadraticBezierTo(
        size.width / 2, size.height - 60, size.width, size.height - 20);
    path.lineTo(size.width, 0); // Top-right corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
