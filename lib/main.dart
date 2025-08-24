import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/screens/otp_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart'; // ✅ added for force update
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString('phone');
  final otpLoginEnabled = prefs.getString('otpLoginEnabled');
  runApp(MyApp(phone: phone, otpLoginEnabled: otpLoginEnabled));
}

class MyApp extends StatelessWidget {
  final String? phone;
  final String? otpLoginEnabled;

  const MyApp({super.key, this.phone, this.otpLoginEnabled});

  @override
  Widget build(BuildContext context) {
    final bool isOtpLoginEnabled = otpLoginEnabled == 'true';

    Widget defaultScreen;
    if (isOtpLoginEnabled) {
      defaultScreen = const LoginScreen();
    } else if (phone != null) {
      defaultScreen = OTPVerificationScreen(
        phone: phone!,
        otpLoginEnabled: isOtpLoginEnabled,
      );
    } else {
      defaultScreen = const LoginScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UpdateChecker( // ✅ wrap with update checker first
        child: TokenValidator(child: defaultScreen),
      ),
    );
  }
}

/// ✅ Force Update Checker (runs before showing app screens)
class UpdateChecker extends StatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // 🔹 Force update (user cannot skip)
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }

    if (mounted) {
      setState(() {
        _updateChecked = true; // Continue app if no update
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_updateChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}

/// ✅ Token Validator (your original logic for JWT token)
class TokenValidator extends StatelessWidget {
  final Widget child;

  const TokenValidator({super.key, required this.child});

  Future<bool> _isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri1}/PayIn/ValidateToken'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isValid'] == true;
      } else {
        await prefs.remove("token");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTokenValid(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
