import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPinVisible = false;
  bool _isPhoneSubmitted = false;
  bool _isOtpVerified = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showMessage("Enter a valid 10-digit phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/SendResetPinMail');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showMessage("Reset OTP sent to registered email.");
        setState(() => _isPhoneSubmitted = true);
      } else {
        _showMessage(data['message'] ?? "Failed to send reset mail.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage("Enter the 6-digit OTP sent to your email.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/VerifyResetPinOTP');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "otp": otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showMessage("OTP verified. You can now set a new PIN.");
        setState(() => _isOtpVerified = true);
      } else {
        _showMessage(data['message'] ?? "Invalid OTP.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPin() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmController.text.trim();

    if (pin.length != 6 || confirmPin.length != 6) {
      _showMessage("PIN must be exactly 4 digits.");
      return;
    }

    if (pin != confirmPin) {
      _showMessage("PINs do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/SetPin');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "pin": pin}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showMessage("PIN set successfully.");
        Navigator.pop(context);
      } else {
        _showMessage(data['message'] ?? "Failed to set PIN.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Forgot PIN"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isPhoneSubmitted
            ? (_isOtpVerified ? _buildPinFields() : _buildOtpInput())
            : _buildPhoneInput(),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Enter your registered Phone Number", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitPhone,
                  child: const Text("Send Reset Mail"),
                ),
              ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Enter the OTP sent to your registered email", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: "OTP",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("Verify OTP"),
                ),
              ),
      ],
    );
  }

  Widget _buildPinFields() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Enter your new 6-digit PIN", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !_isPinVisible,
          decoration: InputDecoration(
            labelText: "New PIN",
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isPinVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPinVisible = !_isPinVisible),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !_isPinVisible,
          decoration: const InputDecoration(
            labelText: "Confirm PIN",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitPin,
                  child: const Text("Set PIN"),
                ),
              ),
      ],
    );
  }
}
