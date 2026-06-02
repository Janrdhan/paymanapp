import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/home_screen_app.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/profile_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/reports_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/utilities_screen.dart';
import 'package:paymanapp/screens/HomeContainer/kyc_helper.dart';

class HomeContainer extends StatefulWidget {
  final String userPhone;
  const HomeContainer({super.key, required this.userPhone});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      HomeScreenApp(
        userPhone: widget.userPhone,
        onRefresh: _refreshBalance,
        isB2B: false,
      ),
      const UtilitiesScreen(),
      const ReportsScreen(),
      ProfileScreen(
        userPhone: widget.userPhone,
        onLogout: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
    ]);
  }

  void _refreshBalance() {}

  Future<void> _onTabTapped(int index) async {
    // Check KYC for Services (1) and Reports (2)
    if (index == 1 || index == 2) {
      bool ok = await KYCValidator.checkAndRedirect(context, widget.userPhone);
      if (!ok) return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}