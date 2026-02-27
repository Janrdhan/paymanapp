import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: Text("Insurance",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _insurance("Health Insurance", "0% GST"),
            _insurance("Car Insurance", "Instant policy"),
            _insurance("Bike Insurance", "Renew in seconds"),
          ],
        ),
      ),
    );
  }

  Widget _insurance(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.inter(color: Colors.green)),
            ],
          )
        ],
      ),
    );
  }
}
