import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _phoneKey = 'phone';
  static const _userKycKey = 'kyc_status';

  static Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String phone,
    required bool kycStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_phoneKey, phone);
    await prefs.setBool(_userKycKey, kycStatus);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  static Future<bool?> getKycStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userKycKey);
  }


  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
