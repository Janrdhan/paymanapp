import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/LogIn/login_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class AuthService {
  // 🔹 SEND OTP
  static Future<bool> sendOtp(String phone) async {
  try {
    final res = await http
        .post(
          Uri.parse('${ApiHandler.baseUri}/Auth/SendOtp'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phone": phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return data["success"] == true;
    }

    return false;
  } catch (e) {
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
          .timeout(const Duration(seconds: 10));

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
          .timeout(const Duration(seconds: 10));

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
      return false;
    }
  }

  // 🔹 FETCH BALANCE (requires valid token)
  static Future<double?> fetchBalance(String phone, String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiHandler.baseUri1}/User/Balance?phone=$phone'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['balance'] ?? 0.0).toDouble();
      }
      return null;
    } catch (_) {
      return null;
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

  // 🔹 FETCH TRANSACTIONS (with date range)
static Future<List<Map<String, dynamic>>> getTransactions({
  required String startDate, // format 'YYYY-MM-DD'
  required String endDate,
}) async {
  try {
    final token = await SessionManager.getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse('${ApiHandler.baseUri1}/User/Transactions?startDate=$startDate&endDate=$endDate'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  } catch (_) {
    return [];
  }
}
}