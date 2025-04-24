import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  const OTPVerificationScreen({required this.phone, super.key});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpVisible = false;
  bool _isResending = false;
  bool _isOtpEntered = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {
        _isOtpEntered = _otpController.text.length == 4;
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOTP() async {
    String otp = _otpController.text.trim();
    if (otp.length != 4) {
      _showMessage("Please enter a valid 4-digit OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/Auth/VerifyOTP');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone, "otp": otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        print("🔵 token: ${data['token']}");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
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

  Future<void> resendOTP() async {
    setState(() => _isResending = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/Auth/ResendOTP');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showMessage("A new OTP has been sent to ${widget.phone}");
      } else {
        _showMessage("Failed to resend OTP. Try again.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your mobile number')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter 4-digit Passcode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: !_isOtpVisible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 10),
                  decoration: InputDecoration(
                    hintText: "• • • •",
                    counterText: "",
                    suffixIcon: IconButton(
                      icon: Icon(_isOtpVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isOtpVisible = !_isOtpVisible);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isOtpEntered ? verifyOTP : null,
                        child: const Text("Proceed"),
                      ),
                    ),
              const SizedBox(height: 15),
              _isResending
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: resendOTP,
                      child: const Text("Forgot Passcode? Resend OTP"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
