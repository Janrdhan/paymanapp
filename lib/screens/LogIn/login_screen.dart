import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymanapp/screens/LogIn/otp_screen.dart';
import 'package:paymanapp/screens/LogIn/terms_screen.dart';
import 'package:paymanapp/screens/LogIn/privacy_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _agreed = false;

  Future<void> _sendOtp() async {
    final phone = _controller.text.trim();

    if (phone.length != 10) {
      setState(() => _error = "Enter a valid mobile number");
      return;
    }

    if (!_agreed) {
      setState(() => _error = "You must agree to the terms and privacy policy");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.sendOtp(phone);

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone),
        ),
      );
    } else {
      setState(() => _error = "Failed to send OTP");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled =
        _controller.text.length == 10 && _agreed && !_loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Logo & Brand
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/PaymanFintech.png",
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "PAYMAN",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "UPI • Payments • Finance",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                const Text(
                  "Enter mobile number",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We'll send you an OTP to verify your number",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 32),

                // Phone input
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixText: "+91  ",
                      hintText: "Mobile number",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Enter the mobile number linked with your bank account",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Terms checkbox – simple row (correct alignment)
                Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v!),
                      activeColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                          children: [
                            const TextSpan(text: "I agree to the "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TermsScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "terms of use",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: " and "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PrivacyScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "privacy policy",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Get OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled ? _sendOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.5),
                      shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Get OTP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}