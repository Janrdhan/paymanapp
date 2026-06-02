import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Privacy Policy"),
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
              "Information We Collect",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We collect personal information such as your name, phone number, "
              "email address, and transaction history to provide our services.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "How We Use Your Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We use your information to process payments, verify your identity, "
              "improve our services, and comply with legal obligations.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "Data Security",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We implement industry‑standard security measures to protect your data. "
              "However, no method of transmission over the internet is 100% secure.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Rights",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You may access, correct, or delete your personal information by "
              "contacting our support team.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}