import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class ForgotPinScreen extends StatefulWidget {
  final String userPhone;
  const ForgotPinScreen({super.key, required this.userPhone});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String _error = '';

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/SendForgotPinOtp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userPhone": widget.userPhone}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your registered mobile")),
        );
      } else {
        setState(() => _error = data['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPin() async {
    final otp = _otpController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() => _error = "Enter valid OTP");
      return;
    }
    if (newPin.isEmpty || newPin.length != 6) {
      setState(() => _error = "PIN must be 6 digits");
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = "PINs do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/ResetPin'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userPhone": widget.userPhone,
          "otp": otp,
          "newPin": newPin,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN reset successfully")),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = data['message'] ?? "Failed to reset PIN");
      }
    } catch (e) {
      setState(() => _error = "Network error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Forgot PIN"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reset your PIN",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We'll send an OTP to your registered mobile number",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_otpSent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Send OTP", style: TextStyle(fontSize: 16)),
                ),
              ),
            if (_otpSent) ...[
              _buildInputField(_otpController, "Enter OTP", Icons.sms, obscure: false),
              const SizedBox(height: 16),
              _buildInputField(_newPinController, "New PIN", Icons.lock, obscure: true),
              const SizedBox(height: 16),
              _buildInputField(_confirmPinController, "Confirm New PIN", Icons.lock_outline, obscure: true),
              const SizedBox(height: 16),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Reset PIN", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: obscure ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}