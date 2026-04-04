import 'package:flutter/material.dart';
import 'package:paymanapp/screens/HomeContainer/home_container.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill {
  String _otp = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void codeUpdated() {
    if (code == null) return;
    setState(() => _otp = code!);
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6 || _loading) return;

    setState(() => _loading = true);

    final res = await AuthService.verifyOtp(widget.phone, _otp);

    if (!mounted) return;

    if (res != null) {
      await SessionManager.saveSession(
        token: res['token'],
        refreshToken: res['refreshToken'],
        phone: widget.phone,
        kycStatus: res['kycCompleted'] ?? false,
      );

      // ✅ FIXED NAVIGATION
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeContainer(userPhone: widget.phone),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or expired OTP")),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone =
        "******${widget.phone.substring(widget.phone.length - 4)}";
    final bool isOtpValid = _otp.length == 6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// 🔹 BRAND
              Center(
                child: Text(
                  "PAYMAN",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                "Enter OTP",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              Text(
                "We’ve sent a 6-digit OTP to +91 $maskedPhone",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 36),

              /// OTP FIELD
              Center(
                child: PinFieldAutoFill(
                  codeLength: 6,
                  currentCode: _otp,
                  keyboardType: TextInputType.number,
                  decoration: BoxLooseDecoration(
                    gapSpace: 12,
                    radius: const Radius.circular(12),
                    strokeColorBuilder:
                        FixedColorBuilder(const Color(0xFF2563EB)),
                    bgColorBuilder:
                        FixedColorBuilder(const Color(0xFFF5F5F5)),
                  ),
                  onCodeChanged: (value) {
                    setState(() {
                      _otp = value ?? "";
                    });
                  },
                ),
              ),

              const SizedBox(height: 18),

              const Center(
                child: Text(
                  "OTP will be auto-detected on supported devices",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const Spacer(),

              /// VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isOtpValid && !_loading ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
                          "Verify OTP",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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