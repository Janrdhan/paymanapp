import 'package:flutter/material.dart';
import '../HomeContainer/home_container.dart';
import 'login_screen.dart';
import '../Services/auth_service.dart';
import '../Services/session_manager.dart';

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

  // 🔍 CHECK LOGIN SESSION
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 1));

    final phone = await SessionManager.getPhone();
    final token = await SessionManager.getToken();
    final refreshToken = await SessionManager.getRefreshToken();

    if (!mounted) return;

    // ❌ Never logged in
    if (phone == null || phone.isEmpty || refreshToken == null) {
      _goLogin();
      return;
    }

    // ✅ Token valid
    if (token != null && !AuthService.isTokenExpired(token)) {
      _goHome(phone);
      return;
    }

    // 🔁 Silent token refresh
    final newToken = await AuthService.refreshAccessToken(refreshToken);

    if (newToken != null) {
      await SessionManager.saveToken(newToken);
    }

    // ⚠ Even if refresh fails → go home (like PhonePe)
    _goHome(phone);
  }

  // 🔐 GO TO LOGIN
  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // 🏠 GO TO HOME (FIXED)
  void _goHome(String phone) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeContainer(userPhone: phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}