import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Terms of Use"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "1. Introduction",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Welcome to PAYMAN. By using our services, you agree to these terms. "
              "Please read them carefully.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "2. Eligibility",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You must be at least 18 years old and have a valid bank account "
              "to use our services.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "3. Privacy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your privacy is important to us. Our Privacy Policy explains how "
              "we collect and use your information.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "4. Changes to Terms",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We may modify these terms at any time. Continued use of the app "
              "means you accept the changes.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}