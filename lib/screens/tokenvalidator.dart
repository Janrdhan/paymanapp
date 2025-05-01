import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';

class TokenValidator extends StatefulWidget {
  final Widget child;

  const TokenValidator({super.key, required this.child});

  @override
  _TokenValidatorState createState() => _TokenValidatorState();
}

class _TokenValidatorState extends State<TokenValidator> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateToken();
    });
  }

  Future<void> _validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint("Token fetched: $token");

    if (token == null || Jwt.isExpired(token)) {
      debugPrint("Token is missing or expired.");
      _goToLogin();
      return;
    }

    if (await _isTokenExpiredOnServer(token)) {
      _goToLogin();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _isTokenExpiredOnServer(String token) async {
    final url = Uri.parse('${ApiHandler.baseUri1}/PayIn/ValidateToken');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return !(data['isValid'] ?? false);
      }
      return true;
    } catch (e) {
      debugPrint('Error validating token: $e');
      return true;
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : widget.child;
  }
}
