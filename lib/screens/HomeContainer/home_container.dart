import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Bpps/bbps_billers_screen.dart';
import 'package:paymanapp/screens/Core/fintech_icon_tile.dart';

class HomeContainer extends StatelessWidget {
  final String userPhone;

  const HomeContainer({super.key, required this.userPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "PAYMAN",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 BALANCE CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.account_balance_wallet, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Wallet Balance ₹0",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 RECHARGE & BILLS CARD
            _sectionCard(
              title: "Recharge & Bills",
              child: _grid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final items = [
      {"name": "Mobile", "icon": Icons.phone_android},
      {"name": "Credit Card", "icon": Icons.credit_card},
      {"name": "Electricity", "icon": Icons.flash_on},
      {"name": "FASTag", "icon": Icons.local_shipping},
      {"name": "DTH", "icon": Icons.tv},
      {"name": "Municipal", "icon": Icons.location_city},
      {"name": "Insurance", "icon": Icons.security},
      {"name": "Loan", "icon": Icons.account_balance},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (_, i) {
        final item = items[i];

        return FintechIconTile(
          icon: item["icon"] as IconData,
          label: item["name"] as String,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BBPSBillersScreen(
                  category: item["name"] as String,
                  userPhone: userPhone,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Text("View All",
                  style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}