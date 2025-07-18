import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandedSplashScreen extends StatelessWidget {
  const BrandedSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Alpha Flow',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'BY BLACKMERE',
              style: GoogleFonts.sora(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 