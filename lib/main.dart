import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/screens/otp_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString('phone');
  runApp(MyApp(phone: phone));
}

class MyApp extends StatelessWidget {
  final String? phone;

  const MyApp({super.key, this.phone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TokenValidator(
        child: phone != null ? OTPVerificationScreen(phone: phone!) : const LoginScreen(),
      ),
    );
  }
}

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
          "Content-Type": "application/json", // ✅ Added Content-Type
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isValid'] == true;
      } else {
        await prefs.remove("token"); // Clear invalid token
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
          return child; // ✅ Token valid, go to app
        } else {
          return const LoginScreen(); // ❌ Invalid, redirect to login
        }
      },
    );
  }
}
