import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/profile_screen.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';

class KYCValidator {
  static Future<bool> checkAndRedirect(BuildContext context, String userPhone) async {
    bool kycCompleted = await SessionManager.isKycCompleted();
    if (!kycCompleted) {
      kycCompleted = await AuthService.refreshKYCStatus(userPhone);
    }
    if (!kycCompleted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("KYC Required"),
          content: const Text(
            "Please complete your KYC (Aadhaar & PAN) to access this feature.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      userPhone: userPhone,
                      onLogout: () {},
                    ),
                  ),
                );
              },
              child: const Text("Go to Profile"),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}