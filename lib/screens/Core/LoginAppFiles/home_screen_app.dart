import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Bpps/bbps_billers_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/bills_recharges_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/category_listing_screen.dart';

class HomeScreenApp extends StatefulWidget {
  final String userPhone;
  final String userName;
  final double balance;
  final bool isLoadingBalance;
  final VoidCallback onRefresh;
  final bool isB2B;

  const HomeScreenApp({
    super.key,
    required this.userPhone,
    required this.userName,
    required this.balance,
    required this.isLoadingBalance,
    required this.onRefresh,
    required this.isB2B,
  });

  @override
  State<HomeScreenApp> createState() => _HomeScreenAppState();
}

class _HomeScreenAppState extends State<HomeScreenApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("PAYMAN"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black87),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLoanCard(),
              const SizedBox(height: 20),
              _buildMoneyTransferRow(),
              const SizedBox(height: 20),
              _buildSbiCardPromo(),
              const SizedBox(height: 20),
              _buildRechargeBillsGrid(),
              const SizedBox(height: 24),
              _buildLoansSection(),
              const SizedBox(height: 24),
              _buildGoldSilverSection(),
              const SizedBox(height: 24),
              _buildInsuranceSection(),
              const SizedBox(height: 24),
              _buildMutualFundsSection(),
              const SizedBox(height: 24),
              _buildTravelTransitSection(),
              const SizedBox(height: 24),
              _buildManagePaymentsSection(),
              const SizedBox(height: 24),
              _buildRewardsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 1. Personal Loan Card ----------
  Widget _buildLoanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Get a personal loan of up to",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  "₹9,05,000",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Apply now",
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ---------- 2. Money Transfer Row ----------
  Widget _buildMoneyTransferRow() {
    final items = [
      {'label': 'To Mobile\nNumber', 'icon': Icons.phone_android, 'color': Colors.green},
      {'label': 'To Bank &\nSelf A/c', 'icon': Icons.account_balance, 'color': Colors.blue},
      {'label': 'PhonePe\nWallet', 'icon': Icons.wallet, 'color': Colors.purple},
      {'label': 'Check\nBalance', 'icon': Icons.balance, 'color': Colors.orange},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        return _buildIconTile(
          icon: item['icon'] as IconData,
          label: item['label'] as String,
          color: item['color'] as Color,
          onTap: () => _gotoBBPS(context, item['label'] as String),
        );
      }).toList(),
    );
  }

  // ---------- 3. SBI Card Promo ----------
  Widget _buildSbiCardPromo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "First Year Free : SBI Card",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Get ₹9,05,000 Personal Loan",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Apply",
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 4. Recharge & Bills Grid ----------
  Widget _buildRechargeBillsGrid() {
    final items = [
      {'name': 'Mobile\nRecharge', 'icon': Icons.phone_android, 'color': Colors.blue, 'category': 'Mobile Recharge'},
      {'name': 'Tuition\nFees', 'icon': Icons.school, 'color': Colors.teal, 'category': 'Education Fees'},
      {'name': 'Electricity\nBill', 'icon': Icons.flash_on, 'color': Colors.orange, 'category': 'Electricity'},
      {'name': 'Loan\nRepayment', 'icon': Icons.account_balance, 'color': Colors.purple, 'category': 'Loan Repayment'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recharge & Bills", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Free Delivery of Jio SIM",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillsRechargesScreen(userPhone: widget.userPhone),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 5. Loans Section ----------
  Widget _buildLoansSection() {
    final items = [
      {'name': 'Personal\nLoan', 'icon': Icons.attach_money, 'color': Colors.green, 'category': 'Personal Loan'},
      {'name': 'Mutual Funds\nLoan', 'icon': Icons.trending_up, 'color': Colors.orange, 'category': 'Mutual Funds Loan'},
      {'name': 'Gold\nLoan', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'category': 'Gold Loan'},
      {'name': 'Credit Score\nFREE', 'icon': Icons.credit_score, 'color': Colors.blue, 'category': 'Credit Score'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Loans", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Get loan of up to ₹9,05,000",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Loans",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'Personal Loan', 'icon': Icons.attach_money, 'color': Colors.green, 'category': 'Personal Loan'},
                    {'name': 'Mutual Funds Loan', 'icon': Icons.trending_up, 'color': Colors.orange, 'category': 'Mutual Funds Loan'},
                    {'name': 'Gold Loan', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'category': 'Gold Loan'},
                    {'name': 'Credit Score', 'icon': Icons.credit_score, 'color': Colors.blue, 'category': 'Credit Score'},
                    {'name': 'Home Loan', 'icon': Icons.home, 'color': Colors.indigo, 'category': 'Home Loan'},
                    {'name': 'Car Loan', 'icon': Icons.directions_car, 'color': Colors.teal, 'category': 'Car Loan'},
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 6. Gold & Silver Section ----------
  Widget _buildGoldSilverSection() {
    final items = [
      {'name': 'Daily Gold\nwith ₹10', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'category': 'Gold'},
      {'name': 'Buy Gold', 'icon': Icons.shopping_bag, 'color': Colors.orange, 'category': 'Gold'},
      {'name': 'Daily Silver\nwith ₹10', 'icon': Icons.workspace_premium, 'color': Colors.grey, 'category': 'Silver'},
      {'name': 'Buy Silver', 'icon': Icons.shopping_bag, 'color': Colors.blueGrey, 'category': 'Silver'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gold & Silver", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "CaratLane Jewellery Scheme",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Gold & Silver",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'Daily Gold with ₹10', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'category': 'Gold'},
                    {'name': 'Buy Gold', 'icon': Icons.shopping_bag, 'color': Colors.orange, 'category': 'Gold'},
                    {'name': 'Daily Silver with ₹10', 'icon': Icons.workspace_premium, 'color': Colors.grey, 'category': 'Silver'},
                    {'name': 'Buy Silver', 'icon': Icons.shopping_bag, 'color': Colors.blueGrey, 'category': 'Silver'},
                    {'name': 'Gold ETF', 'icon': Icons.trending_up, 'color': Colors.deepOrange, 'category': 'Gold ETF'},
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "💡 Did you know? You can save 10% on your Bills*",
            style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A)),
          ),
        ),
      ],
    );
  }

  // ---------- 7. Insurance Section ----------
  Widget _buildInsuranceSection() {
    final items = [
      {'name': 'Bike', 'icon': Icons.moped, 'color': Colors.deepOrange, 'category': 'Bike Insurance'},
      {'name': 'Car', 'icon': Icons.directions_car, 'color': Colors.blue, 'category': 'Car Insurance'},
      {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.green, 'category': 'Health Insurance'},
      {'name': 'Life', 'icon': Icons.favorite, 'color': Colors.red, 'category': 'Life Insurance'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Insurance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Save ₹2500* on Health Policy",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Insurance",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'Bike', 'icon': Icons.moped, 'color': Colors.deepOrange, 'category': 'Bike Insurance'},
                    {'name': 'Car', 'icon': Icons.directions_car, 'color': Colors.blue, 'category': 'Car Insurance'},
                    {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.green, 'category': 'Health Insurance'},
                    {'name': 'Life', 'icon': Icons.favorite, 'color': Colors.red, 'category': 'Life Insurance'},
                    {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.indigo, 'category': 'Travel Insurance'},
                    {'name': 'Property', 'icon': Icons.house, 'color': Colors.brown, 'category': 'Property Insurance'},
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 8. Mutual Funds Section ----------
  Widget _buildMutualFundsSection() {
    final items = [
      {'name': 'Best SIP\nFunds', 'icon': Icons.trending_up, 'color': Colors.green, 'category': 'SIP Funds'},
      {'name': 'Choti SIP\nwith ₹250', 'icon': Icons.attach_money, 'color': Colors.blue, 'category': 'SIP'},
      {'name': 'High Growth\nFunds', 'icon': Icons.trending_up, 'color': Colors.purple, 'category': 'High Growth'},
      {'name': 'Daily SIP\nwith ₹10', 'icon': Icons.repeat, 'color': Colors.orange, 'category': 'Daily SIP'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mutual Funds", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Start a SIP in 5 seconds",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Mutual Funds",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'Best SIP Funds', 'icon': Icons.trending_up, 'color': Colors.green, 'category': 'SIP Funds'},
                    {'name': 'Choti SIP with ₹250', 'icon': Icons.attach_money, 'color': Colors.blue, 'category': 'SIP'},
                    {'name': 'High Growth Funds', 'icon': Icons.trending_up, 'color': Colors.purple, 'category': 'High Growth'},
                    {'name': 'Daily SIP with ₹10', 'icon': Icons.repeat, 'color': Colors.orange, 'category': 'Daily SIP'},
                    {'name': 'Large Cap Funds', 'icon': Icons.business, 'color': Colors.teal, 'category': 'Large Cap'},
                    {'name': 'Mid Cap Funds', 'icon': Icons.show_chart, 'color': Colors.indigo, 'category': 'Mid Cap'},
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 9. Travel & Transit Section ----------
  Widget _buildTravelTransitSection() {
    final items = [
      {'name': 'Flight', 'icon': Icons.flight, 'color': Colors.indigo, 'category': 'Flight Booking'},
      {'name': 'Bus', 'icon': Icons.directions_bus, 'color': Colors.teal, 'category': 'Bus Booking'},
      {'name': 'Train', 'icon': Icons.train, 'color': Colors.brown, 'category': 'Train Booking'},
      {'name': 'Hotel', 'icon': Icons.hotel, 'color': Colors.pink, 'category': 'Hotel Booking'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Travel & Transit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Save up to 30% on Hotels",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Travel & Transit",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'Flight', 'icon': Icons.flight, 'color': Colors.indigo, 'category': 'Flight Booking'},
                    {'name': 'Bus', 'icon': Icons.directions_bus, 'color': Colors.teal, 'category': 'Bus Booking'},
                    {'name': 'Train', 'icon': Icons.train, 'color': Colors.brown, 'category': 'Train Booking'},
                    {'name': 'Hotel', 'icon': Icons.hotel, 'color': Colors.pink, 'category': 'Hotel Booking'},
                    {'name': 'Cabs', 'icon': Icons.taxi_alert, 'color': Colors.deepOrange, 'category': 'Cab Booking'},
                    {'name': 'Holiday Packages', 'icon': Icons.beach_access, 'color': Colors.cyan, 'category': 'Holiday Packages'},
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 10. Manage Payments Section ----------
  Widget _buildManagePaymentsSection() {
    final items = [
      {'name': 'RuPay on\nUPI', 'icon': Icons.payment, 'color': Colors.blue, 'category': 'RuPay'},
      {'name': 'Wish Credit\nCard', 'icon': Icons.credit_card, 'color': Colors.purple, 'category': 'Credit Card'},
      {'name': 'PhonePe\nHDFC card', 'icon': Icons.credit_card, 'color': Colors.indigo, 'category': 'HDFC Card'},
      {'name': 'PhonePe\nSBI card', 'icon': Icons.credit_card, 'color': Colors.red, 'category': 'SBI Card'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Manage Payments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPromoRow(
          title: "Zero Joining Fee: SBI Card",
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryListingScreen(
                  title: "Manage Payments",
                  userPhone: widget.userPhone,
                  items: const [
                    {'name': 'RuPay on UPI', 'icon': Icons.payment, 'color': Colors.blue, 'category': 'RuPay'},
                    {'name': 'Wish Credit Card', 'icon': Icons.credit_card, 'color': Colors.purple, 'category': 'Credit Card'},
                    {'name': 'PhonePe HDFC card', 'icon': Icons.credit_card, 'color': Colors.indigo, 'category': 'HDFC Card'},
                    {'name': 'PhonePe SBI card', 'icon': Icons.credit_card, 'color': Colors.red, 'category': 'SBI Card'},
                    {'name': 'Bill Payments', 'icon': Icons.receipt, 'color': Colors.green, 'category': 'Bill Payments'},
                    {'name': 'AutoPay', 'icon': Icons.schedule, 'color': Colors.orange, 'category': 'AutoPay'},
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- 11. Rewards Section ----------
  Widget _buildRewardsSection() {
    final items = [
      {'name': 'Offers For\nYou', 'icon': Icons.local_offer, 'color': Colors.orange, 'category': 'Offers'},
      {'name': 'Most\nPopular', 'icon': Icons.star, 'color': Colors.amber, 'category': 'Popular'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rewards", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return _buildIconTile(
              icon: item['icon'] as IconData,
              label: item['name'] as String,
              color: item['color'] as Color,
              onTap: () => _gotoBBPS(context, item['category'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryListingScreen(
                    title: "Rewards",
                    userPhone: widget.userPhone,
                    items: const [
                      {'name': 'Offers For You', 'icon': Icons.local_offer, 'color': Colors.orange, 'category': 'Offers'},
                      {'name': 'Most Popular', 'icon': Icons.star, 'color': Colors.amber, 'category': 'Popular'},
                      {'name': 'Cashback', 'icon': Icons.money, 'color': Colors.green, 'category': 'Cashback'},
                      {'name': 'Refer & Earn', 'icon': Icons.share, 'color': Colors.blue, 'category': 'Refer & Earn'},
                    ],
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            child: const Text("More →"),
          ),
        ),
      ],
    );
  }

  // ---------- Reusable Icon Tile ----------
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

  // ---------- Reusable Promo Row ----------
  Widget _buildPromoRow({required String title, required VoidCallback onMoreTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onMoreTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("More →"),
          ),
        ],
      ),
    );
  }

  // ---------- Navigation Helper ----------
  void _gotoBBPS(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BBPSBillersScreen(
          category: category,
          userPhone: widget.userPhone,
        ),
      ),
    );
  }
}