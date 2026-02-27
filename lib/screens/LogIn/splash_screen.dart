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

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 1));

    final phone = await SessionManager.getPhone();
    final token = await SessionManager.getToken();
    final refreshToken = await SessionManager.getRefreshToken();

    if (!mounted) return;

    // ❌ Never logged in
    if (phone == null || refreshToken == null) {
      _goLogin();
      return;
    }

    // ✅ Token valid
    if (token != null && !AuthService.isTokenExpired(token)) {
      _goHome();
      return;
    }

    // 🔁 Silent refresh
    final newToken =
        await AuthService.refreshAccessToken(refreshToken);

    if (newToken != null) {
      await SessionManager.saveToken(newToken);
    }

    // ⚠ Even if refresh fails → Home (PhonePe behavior)
    _goHome();
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeContainer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
