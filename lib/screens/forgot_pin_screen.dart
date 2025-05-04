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
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPinVisible = false;
  bool _isPhoneSubmitted = false;

  @override
  void dispose() {
    _phoneController.dispose();
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
        _showMessage("Reset mail sent successfully.");
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

  Future<void> _submitPin() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
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
      appBar: AppBar(title: const Text("Forgot PIN")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isPhoneSubmitted ? _buildPinFields() : _buildPhoneInput(),
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

  Widget _buildPinFields() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Enter your new 4-digit PIN", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
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
          maxLength: 4,
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
