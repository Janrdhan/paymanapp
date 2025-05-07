import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paymanapp/screens/bank_list.dart';
import 'package:paymanapp/screens/payin.dart';
import 'package:paymanapp/screens/tokenvalidator.dart';
import 'package:paymanapp/screens/user_profile_screen.dart';
import 'package:paymanapp/screens/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String phone;
  const DashboardScreen({required this.phone, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  int _currentPage = 0;
  late final Timer _carouselTimer;

  final List<String> imagePaths = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= imagePaths.length) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryScreen(phone: widget.phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TokenValidator(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text('PAYMAN Dashboard', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(phone: widget.phone)),
                );
              },
            ),
          ],
        ),
        body: _buildDashboardBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildAccordionImages(),
          const SizedBox(height: 16),
          _buildMoneyTransfers(),
          const Divider(thickness: 1, height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Services", style: Theme.of(context).textTheme.titleMedium),
          ),
          _buildServiceGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccordionImages() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePaths[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoneyTransfers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTransferOption(Icons.arrow_downward, 'Pay In', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PayInScreen(phone: widget.phone)));
          }),
          _buildTransferOption(Icons.receipt_long, 'CC Bill', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CreditCardBillersScreen(phone: widget.phone)));
          }),
          _buildTransferOption(Icons.account_balance_wallet, 'Check balance', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Feature coming soon!")),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransferOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.purple.shade100,
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    final List<Map<String, dynamic>> services = [
      {'icon': Icons.flash_on, 'label': 'Recharge & Bills'},
      {'icon': Icons.flight, 'label': 'Travel & Stays'},
      {'icon': Icons.directions_car, 'label': 'Commute'},
      {'icon': Icons.monetization_on, 'label': 'Loans'},
      {'icon': Icons.security, 'label': 'Insurance'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${services[index]['label']} tapped")),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Icon(services[index]['icon'], color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      services[index]['label'],
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
    );
  }
}
