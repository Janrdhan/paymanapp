import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/HomeContainer/home_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class DigiLockerWebView extends StatefulWidget {
  final String url;
  final String verificationId;
  final void Function(String message) onVerified;

  const DigiLockerWebView({
    super.key,
    required this.url,
    required this.verificationId,
    required this.onVerified,
  });

  @override
  State<DigiLockerWebView> createState() => _DigiLockerWebViewState();
}

class _DigiLockerWebViewState extends State<DigiLockerWebView> {
  late final WebViewController _controller;

  bool _checking = false;
  bool _accessEstablished = false;

  void _goToDashboard() async {
    final phone = await SessionManager.getPhone();

    if (phone == null) {
      _showMessage("Session expired. Please login again.");
      setState(() => _checking = false);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeContainer(userPhone: phone), // Pass phone if needed
      ),
      (Route<dynamic> route) => false, // removes all previous routes
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // 🔹 DigiLocker success page detection
            if (url.contains("success") ||
                url.contains("consent") ||
                url.contains("digilocker")) {
              setState(() => _accessEstablished = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // ---------------- CHECK DIGILOCKER STATUS ----------------
  Future<void> _checkStatus() async {
    if (_checking) return;

    setState(() => _checking = true);

    final phone = await SessionManager.getPhone();
    if (phone == null) {
      _showMessage("Session expired. Please login again.");
      setState(() => _checking = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiHandler.baseUri}/Kyc/GetDigiLockerStatus"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Phone": phone,
          "VerificationId": widget.verificationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final bool isSuccess = data["isSuccess"] ?? false;
        final String status = data["status"] ?? "";
        final String message = data["message"] ?? "";
        if(isSuccess){
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("kycStatus", isSuccess);
        }


        if (isSuccess && status == "VERIFIED") {
          // ✅ SUCCESS → GO TO HOME
          widget.onVerified(
            message.isNotEmpty
                ? message
                : "Aadhaar verified successfully via DigiLocker",
          );

          Navigator.pop(context); // close webview
        } else if (status == "PENDING") {
          _showMessage(
            message.isNotEmpty
                ? message
                : "Verification is still in progress. Please wait.",
          );
        } else {
          _showMessage(
            message.isNotEmpty
                ? message
                : "Verification failed. Please try again.",
          );
        }
      } else {
        _showMessage("Unable to verify status. Please try again.");
      }
    } catch (_) {
      _showMessage("Network error. Please check your internet.");
    }

    setState(() => _checking = false);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aadhaar Verification"),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_checking)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      // 🔹 Continue button ONLY after DigiLocker access established
      floatingActionButton: _accessEstablished
          ? FloatingActionButton.extended(
              onPressed: _checkStatus,
              icon: const Icon(Icons.check),
              label: const Text("Continue"),
            )
          : null,
    );
  }

  // ---------------- MESSAGE DIALOG ----------------
  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("DigiLocker"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: _goToDashboard, // navigate and clear stack
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
