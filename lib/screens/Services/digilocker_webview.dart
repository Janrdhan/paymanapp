import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/Core/LoginAppFiles/profile_screen.dart';
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
  bool _isChecking = false;
  bool _verified = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // Trigger a check whenever a page finishes loading
            _checkStatusOnce();
          },
          onNavigationRequest: (request) {
            // Also check on navigation
            _checkStatusOnce();
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_verified) {
        _checkStatusOnce();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkStatusOnce() async {
    if (_isChecking || _verified) return;
    setState(() => _isChecking = true);

    final phone = await SessionManager.getPhone();
    if (phone == null) {
      _showMessage("Session expired. Please login again.");
      setState(() => _isChecking = false);
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

        if (isSuccess && status == "VERIFIED") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("kycStatus", true);
          _verified = true;
          widget.onVerified(
            message.isNotEmpty ? message : "Aadhaar verified successfully via DigiLocker",
          );
          _pollTimer?.cancel();
          _goToDashboard();
        } else if (status == "PENDING") {
          // Still pending, continue polling silently
        } else {
          _showMessage("Verification failed. Please try again.");
          _pollTimer?.cancel();
        }
      } else {
        // API error, keep polling
      }
    } catch (_) {
      // Network error, keep polling
    }
    setState(() => _isChecking = false);
  }

  void _goToDashboard() async {
    final phone = await SessionManager.getPhone();
    if (phone == null) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userPhone: phone,
          onLogout: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    _pollTimer?.cancel();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("DigiLocker"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aadhaar Verification")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isChecking)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}