import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';
import '../LogIn/login_screen.dart';

class AuthService {
  static const baseUrl = "https://your-api-url.com";

  // 🔹 SEND OTP
  static Future<bool> sendOtp(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiHandler.baseUri1}/Auth/SendOtp'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"phone": phone}),
          )
          .timeout(const Duration(seconds: 5));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  // 🔹 VERIFY OTP
  static Future<Map<String, dynamic>?> verifyOtp(
      String phone, String otp) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiHandler.baseUri1}/Auth/VerifyOtp'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"phone": phone, "otp": otp}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  // 🔹 REFRESH TOKEN
  static Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiHandler.baseUri1}/Auth/RefreshToken'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refreshToken": refreshToken}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        return data["token"];
      }
    } catch (_) {}
    return null;
  }

  // 🔹 JWT EXPIRY CHECK
  static bool isTokenExpired(String token) {
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
      );
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false; // never force logout
    }
  }

  // 🔹 LOGOUT
  static Future<void> logout(BuildContext context) async {
    await SessionManager.clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
