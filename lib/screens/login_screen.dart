import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/add_userpin_screen.dart';
import 'package:paymanapp/screens/otp_screen.dart';
import 'package:paymanapp/screens/privacy.dart';
import 'package:paymanapp/screens/terms.dart';
import 'package:paymanapp/screens/user_profile_screen.dart';
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

  void _validatePhoneNumber(String value) {
    setState(() {
      _isValidNumber = RegExp(r'^[0-9]{10}$').hasMatch(value);
    });
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    if (!_isValidNumber) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/Login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );
     

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['exists'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
         print("login phone $phone");
        await prefs.setString("phone", phone);

        final userDetails = data['userDetails'];
        if (userDetails != null) {
          await prefs.setString("firstName", userDetails['firstName'] ?? "");
          await prefs.setString("lastName", userDetails['lastName'] ?? "");
          await prefs.setString("email", userDetails['email'] ?? "");
          await prefs.setString("customerType", userDetails['customerType'] ?? "");

          bool pinVerified = userDetails['pinVerified'] ?? false;
          bool aadharVerified = userDetails['isAadherVerified'] ?? false;

          if (!aadharVerified) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(phone: phone),
              ),
            );
            return;
          }

          if (pinVerified) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(phone: phone),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserPinScreen(phone: phone),
              ),
            );
          }
        }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Need Help?"),
        content: const Text("If you need assistance, please contact support or check FAQs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset("assets/images/PaymanFintech.png", height: 80),
                const SizedBox(height: 20),
                const Text(
                  "Log in to Payman",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "We will create an account if you don't have one.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

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
                            items: const [
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

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: 200,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isValidNumber ? login : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isValidNumber ? Colors.blue : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Proceed"),
                        ),
                      ),
                const SizedBox(height: 20),

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
                              MaterialPageRoute(builder: (context) => TermsScreen()),
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
                              MaterialPageRoute(builder: (context) => PrivacyScreen()),
                            );
                          },
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
