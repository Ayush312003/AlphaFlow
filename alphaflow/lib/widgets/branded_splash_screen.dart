import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BrandedSplashScreen extends StatefulWidget {
  const BrandedSplashScreen({super.key});

  @override
  State<BrandedSplashScreen> createState() => _BrandedSplashScreenState();
}

class _BrandedSplashScreenState extends State<BrandedSplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade in
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
    // Fade out after 1.8s
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Lottie.asset(
              'assets/splash_animation.json',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Alpha Flow',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 