import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/home_screen_app.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/profile_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/reports_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/utilities_screen.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';

class HomeContainer extends StatefulWidget {
  final String userPhone;
  const HomeContainer({super.key, required this.userPhone});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _selectedIndex = 0;
  double _balance = 0.0;
  bool _loadingBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _loadingBalance = true);

    String? token = await SessionManager.getToken();
    final refreshToken = await SessionManager.getRefreshToken();

    if (token != null && AuthService.isTokenExpired(token)) {
      if (refreshToken != null) {
        final newToken = await AuthService.refreshAccessToken(refreshToken);
        if (newToken != null) {
          token = newToken;
          await SessionManager.saveToken(newToken);
        }
      }
    }

    double? balance;
    if (token != null) {
      balance = await AuthService.fetchBalance(widget.userPhone, token);
    }

    if (mounted) {
      setState(() {
        _balance = balance ?? 0.0;
        _loadingBalance = false;
      });
    }
  }

  void _refreshBalance() => _fetchBalance();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreenApp(
  userPhone: widget.userPhone,
  userName: 'Jurra',          // from SessionManager
  balance: _balance,
  isLoadingBalance: _loadingBalance,
  onRefresh: _refreshBalance,
  isB2B: false,               // from session
),
      const UtilitiesScreen(),
      const ReportsScreen(),
      ProfileScreen(
        userPhone: widget.userPhone,
        onLogout: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2563EB), // blue
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _refreshBalance();
        },
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