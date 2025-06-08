import 'package:flutter/material.dart';

class CustomHomePage extends StatelessWidget {
  const CustomHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Mode'),
      ),
      body: const Center(
        child: Text('Custom Home Page Placeholder'),
      ),
    );
  }
}
