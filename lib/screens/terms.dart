import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMAN FINTECH SOLUTIONS PVT LTD believes in helping its customers as far as possible, and has therefore a liberal cancellation policy.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'This document serves as an electronic record in accordance with the Information Technology Act, 2000, and the relevant rules applicable therein...'
                ' (Add the rest of your content here in similar format)',
                style: TextStyle(fontSize: 14),
              ),
              // Add more sections as needed with proper formatting
            ],
          ),
        ),
      ),
    );
  }
}
