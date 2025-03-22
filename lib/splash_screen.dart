import 'package:flutter/material.dart';
import 'main.dart'; // Import your main.dart file

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main screen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QuestionCreatorApp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue], // Define your two colors
            begin: Alignment.topLeft, // Start gradient from the top-left corner
            end: Alignment
                .bottomRight, // End gradient at the bottom-right corner
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo using final_logo.png
              Image.asset(
                'assets/images/logo_final.png', // Ensure this is correctly defined in pubspec.yaml
                width: 150, // Adjust size as needed
              ),
              const SizedBox(height: 20),
              // App name or title
              const Text(
                'Smart Quiz Creator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
