import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  final String phone;
  const HistoryScreen({super.key,required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: Text("History",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Transaction #${index + 1}",
                    style: GoogleFonts.inter(),
                  ),
                ),
                Text("₹500",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}
