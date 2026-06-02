import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:paymanapp/screens/HomeContainer/home_container.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';

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
    final maskedPhone = "******${widget.phone.substring(widget.phone.length - 4)}";
    final bool isOtpValid = _otp.length == 6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Brand
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
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                "Enter OTP",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We’ve sent a 6-digit OTP to +91 $maskedPhone",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // OTP input field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                child: PinFieldAutoFill(
                  codeLength: 6,
                  currentCode: _otp,
                  keyboardType: TextInputType.number,
                  decoration: BoxLooseDecoration(
                    gapSpace: 12,
                    radius: const Radius.circular(12),
                    strokeColorBuilder: FixedColorBuilder(const Color(0xFF2563EB)),
                    bgColorBuilder: FixedColorBuilder(const Color(0xFFF5F7FA)),
                  ),
                  onCodeChanged: (value) {
                    setState(() => _otp = value ?? "");
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "OTP will be auto-detected on supported devices",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 60),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isOtpValid && !_loading ? _verifyOtp : null,
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
                          "Verify OTP",
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
    );
  }
}