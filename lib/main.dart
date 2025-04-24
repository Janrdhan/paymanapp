//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/screens/otp_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  String? phone = prefs.getString('phone'); // nullable
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

/// TokenValidator Widget — checks token validity on app launch and inside app
class TokenValidator extends StatelessWidget {
  final Widget child;

  const TokenValidator({super.key, required this.child});

  Future<bool> _checkTokenValidity() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Auth/ValidateToken'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // final data = jsonDecode(response.body);
        // return data["isValid"] == true;
        return true;
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
      future: _checkTokenValidity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
