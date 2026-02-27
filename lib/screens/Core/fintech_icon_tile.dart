import 'package:flutter/material.dart';

class FintechIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? badge;

  FintechIconTile({
    super.key,
    required this.icon,
    required this.label,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF6A1B9A)),
            ),
            if (badge != null) Positioned(top: -2, right: -2, child: badge!),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
