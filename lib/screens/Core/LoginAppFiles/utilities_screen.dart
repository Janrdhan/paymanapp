import 'package:flutter/material.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  final List<Map<String, dynamic>> utilities = const [
    {'name': 'Electricity bill', 'icon': Icons.flash_on, 'color': Colors.orange},
    {'name': 'LPG cylinder', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'name': 'Water bill', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Piped gas', 'icon': Icons.local_fire_department, 'color': Colors.teal},
    {'name': 'Municipal services', 'icon': Icons.location_city, 'color': Colors.indigo},
    {'name': 'Municipal taxes', 'icon': Icons.receipt, 'color': Colors.purple},
    {'name': 'Housing / apartment', 'icon': Icons.house, 'color': Colors.brown},
    {'name': 'Clubs & association', 'icon': Icons.people, 'color': Colors.pink},
    {'name': 'Education fees', 'icon': Icons.school, 'color': Colors.green},
    {'name': 'Charitable donation', 'icon': Icons.favorite, 'color': Colors.red},
    {'name': 'OTT & subscription...', 'icon': Icons.live_tv, 'color': Colors.blueGrey},
    {'name': 'Hospital & pathology', 'icon': Icons.local_hospital, 'color': Colors.cyan},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Utilities"),
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black87),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient card
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Utilities list (modern card with colorful icons)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: utilities.length,
                    separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final utility = utilities[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (utility['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(utility['icon'] as IconData, color: utility['color'] as Color, size: 22),
                        ),
                        title: Text(
                          utility['name'] as String,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        onTap: () => _payUtility(context, utility['name'] as String),
                      );
                    },
                  ),
                  // "More services" footer (optional)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 12),
                        Text("More services coming soon", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Add all bills card (redesigned)
            _buildAddBillsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Pay all your utility bills",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Get instant cashback & never miss a due date",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildAddBillsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📅 Add all bills in one click",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Get reminders for all upcoming bills and never miss a due",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Add now", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.sms, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Device SMS will be used", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Stripe_Logo%2C_revised_2016.svg/1280px-Stripe_Logo%2C_revised_2016.svg.png',
                height: 18,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _payUtility(BuildContext context, String utility) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pay $utility'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}