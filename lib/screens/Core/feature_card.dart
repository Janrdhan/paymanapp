import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/app_colors.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String badge;
  final IconData icon;

  const FeatureCard(this.title, this.badge, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            Icon(icon, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
