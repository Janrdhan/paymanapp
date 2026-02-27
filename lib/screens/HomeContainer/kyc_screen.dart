import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:paymanapp/screens/Services/digilocker_webview.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  static const Color paymanBlue = Color(0xff2563EB);

  bool _loading = false;
  bool _verified = false;
  String? _successMessage;

  // ---------------- START DIGILOCKER ----------------
  Future<void> _startDigiLocker() async {
    final phone = await SessionManager.getPhone();
    if (phone == null) {
      _toast("Session expired. Please login again.");
      return;
    }

    setState(() => _loading = true);

    final res = await http.post(
      Uri.parse('${ApiHandler.baseUri}/Kyc/StartDigilocker'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Phone": phone,
        "VerificationId": ""
      }),
    );

    setState(() => _loading = false);

    if (res.statusCode != 200) {
      _toast("Failed to start DigiLocker verification");
      return;
    }

    final data = jsonDecode(res.body);
    final verificationId = data["verification_id"];
    final redirectUrl = data["url"];

    // 📱 MOBILE → WebView
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DigiLockerWebView(
          url: redirectUrl,
          verificationId: verificationId,
          onVerified: (message) {
            setState(() {
              _verified = true;
              _successMessage = message;
            });

            _toast(message);
          },
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete KYC"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xffF6F7FB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _verified
                ? _successCard()
                : _aadhaarCard(),
      ),
    );
  }

  // ---------------- AADHAAR CARD ----------------
  Widget _aadhaarCard() {
    return _card(
      title: "Aadhaar Verification",
      child: Column(
        children: [
          const Text(
            "You will be redirected to DigiLocker to securely share your "
            "Aadhaar details.\n\n"
            "After granting consent in DigiLocker, return to this app to "
            "complete verification.\n\n"
            "No Aadhaar number or OTP is required.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _primaryBtn("Verify via DigiLocker", _startDigiLocker),
        ],
      ),
    );
  }

  // ---------------- SUCCESS CARD ----------------
  Widget _successCard() {
    return _card(
      title: "KYC Completed",
      child: Column(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            _successMessage ??
                "Your Aadhaar has been successfully verified via DigiLocker.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.green,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _primaryBtn("Go to Home", () {
            Navigator.pop(context, true); // notify parent
          }),
        ],
      ),
    );
  }

  // ---------------- UI HELPERS ----------------
  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child
        ],
      ),
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: paymanBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
