import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Bpps/bbps_billers_screen.dart';

class BillsRechargesScreen extends StatelessWidget {
  final String userPhone;
  const BillsRechargesScreen({super.key, required this.userPhone});

  final List<Map<String, dynamic>> telecomItems = const [
    {'name': 'Mobile recharge', 'icon': Icons.phone_android, 'color': Colors.blue, 'isNew': false},
    {'name': 'FASTag recharge', 'icon': Icons.directions_car, 'color': Colors.teal, 'isNew': false},
    {'name': 'Mobile postpaid', 'icon': Icons.phone_iphone, 'color': Colors.indigo, 'isNew': false},
    {'name': 'DTH recharge', 'icon': Icons.tv, 'color': Colors.purple, 'isNew': false},
    {'name': 'Broadband bill', 'icon': Icons.wifi, 'color': Colors.orange, 'isNew': false},
    {'name': 'Landline bill', 'icon': Icons.phone, 'color': Colors.green, 'isNew': false},
    {'name': 'Cable TV', 'icon': Icons.cable, 'color': Colors.brown, 'isNew': false},
    {'name': 'Metro', 'icon': Icons.train, 'color': Colors.blueGrey, 'isNew': true},
    {'name': 'EV recharge', 'icon': Icons.electric_car, 'color': Colors.lightGreen, 'isNew': true},
  ];

  final List<Map<String, dynamic>> financeItems = const [
    {'name': 'Credit card', 'icon': Icons.credit_card, 'color': Colors.blue},
    {'name': 'Loan repayment', 'icon': Icons.account_balance, 'color': Colors.green},
    {'name': 'LIC / insurance', 'icon': Icons.security, 'color': Colors.red},
    {'name': 'Recurring deposit', 'icon': Icons.trending_up, 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> giftCards = const [
    {'name': 'Amazon', 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'name': 'Flipkart', 'icon': Icons.shop, 'color': Colors.blue},
    {'name': 'Zomato', 'icon': Icons.restaurant, 'color': Colors.red},
    {'name': 'Netflix', 'icon': Icons.movie, 'color': Colors.red},
    {'name': 'Spotify', 'icon': Icons.music_note, 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Bills & Recharges"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildCategoryGrid("Telecom & travel", telecomItems, showNewBadge: true),
            const SizedBox(height: 24),
            _buildCategoryGrid("Finance", financeItems),
            const SizedBox(height: 24),
            _buildGiftCardSection(),
            const SizedBox(height: 30),
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
          const Icon(Icons.receipt, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Pay all your bills in one place",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Get instant cashback & rewards",
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

  Widget _buildCategoryGrid(String title, List<Map<String, dynamic>> items, {bool showNewBadge = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          // ✅ Divider removed – no black line
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Stack(
                children: [
                  _buildIconTile(
                    icon: item['icon'] as IconData,
                    label: item['name'] as String,
                    color: item['color'] as Color,
                    onTap: () => _onTapItem(context, item['name'] as String),
                  ),
                  if (showNewBadge && (item['isNew'] ?? false))
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("New", style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCardSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Gift cards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          // ✅ Divider removed
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: giftCards.length,
              itemBuilder: (context, index) {
                final card = giftCards[index];
                return GestureDetector(
                  onTap: () => _onTapItem(context, card['name'] as String),
                  child: Container(
                    width: 85,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: (card['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card['icon'] as IconData, color: card['color'] as Color, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          card['name'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTapItem(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BBPSBillersScreen(
          category: name,
          userPhone: userPhone,
        ),
      ),
    );
  }
}