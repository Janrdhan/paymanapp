import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/otp_screen.dart';
import 'package:paymanapp/screens/privacy.dart';
import 'package:paymanapp/screens/terms.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isValidNumber = false;
  String _countryCode = "+91";

  // ✅ Validate Phone Number (Only 10 Digits)
  void _validatePhoneNumber(String value) {
    setState(() {
      _isValidNumber = RegExp(r'^[0-9]{10}$').hasMatch(value);
    });
  }

  // ✅ API Call to Login
  Future<void> login() async {
    String phone = _phoneController.text.trim();
    if (!_isValidNumber) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/Auth/Login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": "$_countryCode$phone"}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['exists'] == true) {

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("phone", "$_countryCode$phone");
        // await prefs.setString("username", data['name'] ?? "User");
        // await prefs.setString("email", data['email'] ?? "");
        // await prefs.setInt("userId", data['id']);


        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OTPVerificationScreen(phone: "$_countryCode$phone")),
        );
      } else {
        _showMessage("Mobile number not registered.");
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ✅ Show Help Dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Need Help?"),
        content:
            Text("If you need assistance, please contact support or check FAQs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline), // ? Help Icon
            onPressed: _showHelpDialog, // Show Help Dialog
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 App Logo
            Image.asset("assets/images/homelogo.png", height: 80),
            const SizedBox(height: 20),
            const Text(
              "Log in to Payman",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "We will create an account if you don't have one.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 🔹 Mobile Input Field with Country Code
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: _validatePhoneNumber,
              decoration: InputDecoration(
                prefixIcon: Container(
                  width: 105,
                  padding: const EdgeInsets.only(left: 10, right: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _countryCode,
                        underline: const SizedBox(),
                        onChanged: (value) => setState(() => _countryCode = value!),
                        items: [
                          DropdownMenuItem(value: "+91", child: Text("+91")),
                          DropdownMenuItem(value: "+1", child: Text("+1")),
                          DropdownMenuItem(value: "+44", child: Text("+44")),
                          DropdownMenuItem(value: "+61", child: Text("+61")),
                        ],
                      ),
                    ],
                  ),
                ),
                hintText: "Enter Mobile Number",
                border: const OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Proceed Button
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: 200,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isValidNumber ? login : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isValidNumber ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Proceed"),
                    ),
                  ),
            const SizedBox(height: 20),

            // 🔹 Terms & Privacy Policy
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  const TextSpan(text: "By proceeding, you agree to our "),
                  TextSpan(
                    text: "Terms",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TermsScreen()),
                        );
                      },
                  ),
                  const TextSpan(text: " & "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrivacyScreen()),
                        );
                      },
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
