import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:paymanapp/widgets/api_handler.dart';

class AddUserPinScreen extends StatefulWidget {
  final String phone;

  const AddUserPinScreen({super.key, required this.phone});

  @override
  _AddUserPinScreenState createState() => _AddUserPinScreenState();
}

class _AddUserPinScreenState extends State<AddUserPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PINs must match and be 4 digits")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiHandler.baseUri1}/Users/SetPin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": widget.phone,
          "pin": pin,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Optionally return to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PIN set successfully! Please log in.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to set PIN")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Your PIN")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(labelText: "New PIN"),
            ),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(labelText: "Confirm PIN"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitPin,
                    child: Text("Submit PIN"),
                  ),
          ],
        ),
      ),
    );
  }
}
