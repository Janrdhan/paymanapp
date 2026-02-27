import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/fintech_icon_tile.dart';

class RechargeViewAllScreen extends StatelessWidget {
  const RechargeViewAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Services")),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          FintechIconTile(icon: Icons.phone_android, label: "Mobile"),
          FintechIconTile(icon: Icons.wifi, label: "DTH"),
          FintechIconTile(icon: Icons.flash_on, label: "Electricity"),
          FintechIconTile(icon: Icons.water_drop, label: "Water"),
          FintechIconTile(icon: Icons.gas_meter, label: "Gas"),
          FintechIconTile(icon: Icons.school, label: "Education"),
          FintechIconTile(icon: Icons.local_hospital, label: "Insurance"),
          FintechIconTile(icon: Icons.account_balance, label: "Finance"),
        ],
      ),
    );
  }
}
