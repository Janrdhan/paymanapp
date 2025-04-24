import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenValidator extends StatefulWidget {
  final Widget child;

  const TokenValidator({super.key, required this.child});

  @override
  _TokenValidatorState createState() => _TokenValidatorState();
}

class _TokenValidatorState extends State<TokenValidator> {
  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  // Function to validate the token
  Future<void> _validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || await _isTokenExpired(token)) {
      // Token is either null or expired, navigate to Login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Function to check if token is expired
  Future<bool> _isTokenExpired(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Auth/ValidateToken'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        return true; // Token expired or invalid
      }
      final data = jsonDecode(response.body);
      return !(data['isValid'] ?? false); // If not valid, return true (expired)
    } catch (e) {
      return true; // If error occurs, consider token expired
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child; // Return the child screen/widget
  }
}
