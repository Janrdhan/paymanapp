import 'package:flutter/material.dart';
import 'package:paymanapp/screens/bank_list.dart';
import 'package:paymanapp/screens/payin.dart';
import 'package:paymanapp/screens/tokenvalidator.dart';
import 'package:paymanapp/screens/user_profile_screen.dart';
import 'package:paymanapp/screens/history_screen.dart'; // <- Make sure to create this screen.

class DashboardScreen extends StatefulWidget {
  final String phone;
  const DashboardScreen({required this.phone, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryScreen(phone: widget.phone)),
      );
    }
    // You can add logic for other tabs here
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
                  MaterialPageRoute(builder: (context) => UserProfileScreen(phone: widget.phone)),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMoneyTransfers(context),
                    _buildServiceGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildMoneyTransfers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTransferOption(context, Icons.phone, 'To mobile number', PayInScreen(phone: widget.phone)),
          _buildTransferOption(context, Icons.account_balance, 'To bank & self account', CreditCardBillersScreen(phone: widget.phone)),
          _buildTransferOption(context, Icons.account_balance_wallet, 'Check balance', null),
        ],
      ),
    );
  }

  Widget _buildTransferOption(BuildContext context, IconData icon, String label, Widget? targetScreen) {
    return GestureDetector(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.purple.shade100,
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
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
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(services[index]['icon'], color: Colors.blueAccent),
            title: Text(services[index]['label']),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
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
