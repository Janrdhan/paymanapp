import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestScreen extends StatelessWidget {
  const InvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: Text("Invest",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card("Mutual Funds", Icons.trending_up),
            _card("Fixed Deposits", Icons.account_balance),
            _card("Stocks (Coming soon)", Icons.show_chart),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 16)),
        ],
      ),
    );
  }
}
