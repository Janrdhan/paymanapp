import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _agreed = true;

  Future<void> _sendOtp() async {
    final phone = _controller.text.trim();

    if (phone.length != 10) {
      setState(() => _error = "Enter a valid mobile number");
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              /// 🔹 LOGO + BRAND (INLINE)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/PaymanFintech.png",
                    height: 36, // Smaller logo
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "PAYMAN",
                    style: GoogleFonts.inter(
                      fontSize: 22, // Reduced size
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB), // Blue color
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// 🔹 TAGLINE
              const Center(
                child: Text(
                  "UPI • Payments • Finance",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              /// 🔹 TITLE
              const Text(
                "Enter mobile number",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              /// 🔹 PHONE INPUT
              TextField(
                controller: _controller,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: "+91  ",
                  hintText: "Mobile number",
                  counterText: "",
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                "Enter the mobile number linked with your bank account",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              /// 🔹 TERMS
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v!),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(text: "I agree to "),
                          TextSpan(
                            text: "terms of use",
                            style: TextStyle(
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: " & "),
                          TextSpan(
                            text: "privacy policy",
                            style: TextStyle(
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              /// 🔹 GET OTP BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _sendOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Blue button
                    disabledBackgroundColor:
                        const Color(0xFF2563EB).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Get OTP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
