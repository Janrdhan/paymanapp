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
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPinVisible = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _pinController.text.trim();
    final confirmPin = _confirmController.text.trim();

    if (widget.isChangePin && currentPin.length != 6) {
      _showMessage("Current PIN must be exactly 6 digits.");
      return;
    }

    if (newPin.length != 6 || confirmPin.length != 6) {
      _showMessage("New PIN and Confirm PIN must be exactly 6 digits.");
      return;
    }

    if (newPin != confirmPin) {
      _showMessage("New PIN and Confirm PIN do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        widget.isChangePin
            ? '${ApiHandler.baseUri1}/Users/ChangePin'
            : '${ApiHandler.baseUri1}/Users/SetPin',
      );

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.isChangePin
            ? {
                "phone": widget.phone,
                "currentPin": currentPin,
                "newPin": newPin,
              }
            : {
                "phone": widget.phone,
                "pin": newPin,
              }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showMessage(widget.isChangePin ? "PIN changed successfully." : "PIN set successfully.");
        Navigator.pop(context);
      } else {
        _showMessage(data['message'] ?? "Failed to ${widget.isChangePin ? 'change' : 'set'} PIN.");
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
            if (widget.isChangePin) ...[
              const Text("Enter Current PIN", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _currentPinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_isPinVisible,
                decoration: InputDecoration(
                  labelText: "Current PIN",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
                      child: Text(widget.isChangePin ? "Change PIN" : "Set PIN"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
