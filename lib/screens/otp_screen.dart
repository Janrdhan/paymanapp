import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/forgot_pin_screen.dart';
import 'package:paymanapp/screens/set_pin_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final bool otpLoginEnabled;
  const OTPVerificationScreen({required this.phone, required this.otpLoginEnabled, super.key});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpVisible = false;
  final bool _isResending = false;

  @override
  void initState() {
    super.initState();
    if (widget.otpLoginEnabled) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMessage("OTP sent to registered email.");
    });
  }
    _otpController.addListener(() {
      if (_otpController.text.length == 6 && !_isLoading) {
        verifyOTP(); // Auto-submit OTP when 6 digits are entered
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOTP() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage("Please enter a valid 6-digit OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/PayIn/VerifyOTP');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone, "otp": otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardScreen(phone: widget.phone)),
        );
      } else {
        _showMessage("Invalid OTP. Please try again.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToChangePin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPinScreen(phone: widget.phone, isChangePin: true),
      ),
    );
  }

  void _navigateToForgotPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPinScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify PassCode'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                       widget.otpLoginEnabled ? "Enter 6-digit OTP" : "Enter 6-digit Passcode",
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: !_isOtpVisible,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: "- - - - - -",
                      counterText: "",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOtpVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _isOtpVisible = !_isOtpVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  const SizedBox(height: 45), // Placeholder to keep layout stable
                const SizedBox(height: 15),
                _isResending
                    ? const CircularProgressIndicator()
                    : (!widget.otpLoginEnabled
                        ? Column(
                            children: [
                              TextButton(
                                onPressed: _navigateToForgotPin,
                                child: const Text("Forgot PIN?"),
                              ),
                              TextButton(
                                onPressed: _navigateToChangePin,
                                child: const Text("Change PIN"),
                              ),
                            ],
                          )
                        : const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
