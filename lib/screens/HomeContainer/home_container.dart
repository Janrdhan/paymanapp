import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/auto_moving_offers.dart';
import 'package:paymanapp/screens/Core/feature_card.dart';
import 'package:paymanapp/screens/Core/fintech_icon_tile.dart';
import 'package:paymanapp/screens/Core/offer_model.dart';
import 'package:paymanapp/screens/Core/offer_pill.dart';
import 'package:paymanapp/screens/HomeContainer/recharge_view_all_screen.dart';
import 'package:paymanapp/screens/Profile/profile_screen.dart';
import 'package:paymanapp/screens/core/analytics.dart';
import 'package:paymanapp/screens/core/app_colors.dart';

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _currentIndex = 0;

  late final List<OfferModel> moneyOffers;
  late final List<OfferModel> billOffers;

  @override
  void initState() {
    super.initState();

    moneyOffers = [
      OfferModel(Icons.flash_on, "Instant Transfer", const Color(0xffECFDF3)),
      OfferModel(Icons.percent, "0% Charges Today", const Color(0xffFFF7ED)),
      OfferModel(Icons.currency_rupee, "Refer ₹200", const Color(0xffEFF6FF)),
    ];

    billOffers = [
      OfferModel(Icons.local_offer, "Flat ₹50 Cashback", const Color(0xffECFDF3)),
      OfferModel(Icons.flash_on, "Electricity Offer", const Color(0xffEFF6FF)),
      OfferModel(Icons.credit_card, "₹1000 CC Cashback", const Color(0xffFFF7ED)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).padding.top + 90;

    return Scaffold(
      backgroundColor: AppColors.bg,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: headerHeight + 12, bottom: 16),
            child: Column(
              children: [
                _loanBanner(),
                _moneyTransfers(),
                _rechargeBills(context),
                _featureGrid(),
                _managePayments(),
                _rewardsSection(),
              ],
            ),
          ),
          _header(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 100,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
        /// 👤 PROFILE ICON (TAP)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          },
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),

        const SizedBox(width: 10),

        const Text(
          "Welcome PAYMAN",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        const Spacer(),
        const Icon(Icons.help_outline),
      ],
      ),
    );
  }

  Widget _loanBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4A044E), Color(0xff7E1F86)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          "Get a personal loan of up to\n₹7,00,000\n\nApply now →",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _moneyTransfers() {
    return _section(
      "Money Transfers",
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FintechIconTile(icon: Icons.phone_android, label: "To Mobile"),
              FintechIconTile(icon: Icons.account_balance, label: "To Bank"),
              FintechIconTile(icon: Icons.call_received, label: "Receive"),
              FintechIconTile(
                  icon: Icons.account_balance_wallet, label: "Balance"),
            ],
          ),
          const SizedBox(height: 12),
          AutoMovingOffers(items: moneyOffers.map(offerPill).toList()),
        ],
      ),
    );
  }

  Widget _rechargeBills(BuildContext context) {
    return _sectionWithViewAll(
      title: "Recharge & Bills",
      onViewAll: () {
        Analytics.track("recharge_view_all");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RechargeViewAllScreen(),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FintechIconTile(icon: Icons.phone_android, label: "Mobile"),
              FintechIconTile(icon: Icons.credit_card, label: "Credit Card"),
              FintechIconTile(icon: Icons.flash_on, label: "Electricity"),
              FintechIconTile(icon: Icons.payments, label: "Loan"),
            ],
          ),
          const SizedBox(height: 12),
          AutoMovingOffers(items: billOffers.map(offerPill).toList()),
        ],
      ),
    );
  }

  Widget _managePayments() {
    return _sectionWithViewAll(
      title: "Manage Payments",
      onViewAll: () {},
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FintechIconTile(
                  icon: Icons.account_balance_wallet, label: "Wallet"),
              FintechIconTile(icon: Icons.card_giftcard, label: "Wish Card"),
              FintechIconTile(icon: Icons.credit_card, label: "HDFC Card"),
              FintechIconTile(icon: Icons.credit_card, label: "SBI Card"),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: const [
              Icon(Icons.qr_code),
              SizedBox(width: 8),
              Text("My QR"),
              Spacer(),
              Text(
                "UPI ID: janardhan.jurra@ybl",
                style: TextStyle(color: Colors.grey),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Rewards",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text("Offers & Cashbacks"),
                SizedBox(height: 6),
                Chip(label: Text("5 New")),
              ],
            ),
          ),
          const Icon(Icons.card_giftcard,
              size: 36, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _featureGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      padding: const EdgeInsets.all(16),
      children: [
        FeatureCard("Loans", "Resume", Icons.payments),
        FeatureCard("Insurance", "Offer", Icons.security),
        FeatureCard("Gold & Silver", "Buy", Icons.savings),
        FeatureCard("Travel", "Sale", Icons.flight),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sectionWithViewAll({
    required String title,
    required VoidCallback onViewAll,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  "View All",
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
