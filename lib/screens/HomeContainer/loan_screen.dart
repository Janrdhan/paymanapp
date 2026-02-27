import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: Text("Loans",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _loanCard("Personal Loan", "Up to ₹10,00,000"),
            _loanCard("Cash Loan", "Instant approval"),
            _loanCard("Credit Line", "Pay as you use"),
          ],
        ),
      ),
    );
  }

  Widget _loanCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}
