import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import '../HomeContainer/home_container.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 1)); // splash delay

    final phone = await SessionManager.getPhone();
    final token = await SessionManager.getToken();
    final refreshToken = await SessionManager.getRefreshToken();

    if (!mounted) return;

    // No session → login
    if (phone == null || refreshToken == null) {
      _goLogin();
      return;
    }

    // Token valid → go home
    if (token != null && !AuthService.isTokenExpired(token)) {
      _goHome(phone);
      return;
    }

    // Silent refresh
    final newToken = await AuthService.refreshAccessToken(refreshToken);
    if (newToken != null) {
      await SessionManager.saveToken(newToken);
    }
    // Even if refresh fails, go home (like PhonePe)
    _goHome(phone);
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goHome(String phone) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeContainer(userPhone: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}