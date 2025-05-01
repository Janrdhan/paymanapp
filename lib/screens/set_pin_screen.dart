import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class SetPinScreen extends StatefulWidget {
  final String phone;
  final bool isChangePin;

  const SetPinScreen({required this.phone, this.isChangePin = false, super.key});

  @override
  _SetPinScreenState createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isPinVisible = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
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
        body: jsonEncode({
          "phone": widget.phone,
          "pin": pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showMessage("${widget.isChangePin ? 'PIN changed' : 'PIN set'} successfully.");
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChangePin ? "Change PIN" : "Set PIN"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your 4-digit ${"PIN"}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              decoration: InputDecoration(
                labelText: "Confirm PIN",
                border: const OutlineInputBorder(),
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
                      child: Text(widget.isChangePin ? "Change PIN" : "Set PIN"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
