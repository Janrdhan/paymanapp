import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/HomeContainer/kyc_screen.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color paymanBlue = Color(0xff2563EB);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _gender = "Male";

  bool _loading = true;
  bool _isEditable = false;

  bool _isAadhaarVerified = false;
  bool _isPanVerified = false;
  bool _isKycCompleted = false;

  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    final token = await SessionManager.getToken();
    final phone = await SessionManager.getPhone();

    final res = await http.post(
      Uri.parse('${ApiHandler.baseUri1}/profile/GetProfile'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "phone": phone,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        _nameCtrl.text = data["name"] ?? "";
        _emailCtrl.text = data["email"] ?? "";
        _phoneCtrl.text = data["phone"] ?? "";

        _gender = (data["gender"] == "Male" ||
                data["gender"] == "Female" ||
                data["gender"] == "Other")
            ? data["gender"]
            : "Male";

        _isAadhaarVerified = data["isAadhaarVerified"] == true;
        _isPanVerified = data["isPanVerified"] == true;
        _isKycCompleted = data["isKycCompleted"] == true;

        _profileImageBase64 = data["profileImageBase64"];

        // Editable only if profile is empty
        _isEditable = _nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty;

        _loading = false;
      });
    }
  }

  // ---------------- UPDATE PROFILE ----------------
  Future<void> _saveProfile() async {
    if (!_isEditable) return;

    final token = await SessionManager.getToken();

    await http.post(
      Uri.parse('${ApiHandler.baseUri1}/profile/UpdateProfile'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": _nameCtrl.text,
        "email": _emailCtrl.text,
        "gender": _gender,
      }),
    );

    setState(() => _isEditable = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logout() async {
    //await SessionManager.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileHeader(),
            const SizedBox(height: 20),
            _profileDetails(),
            const SizedBox(height: 20),
            _kycSection(),
            const SizedBox(height: 20),
            _logoutTile(),
          ],
        ),
      ),
    );
  }

  // ---------------- PROFILE HEADER ----------------
  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameCtrl.text,
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_phoneCtrl.text,
                    style: GoogleFonts.inter(color: Colors.grey)),
                const SizedBox(height: 6),
                _kycBadge(),
              ],
            ),
          ),
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (_profileImageBase64 != null &&
                    _profileImageBase64!.isNotEmpty)
                ? MemoryImage(base64Decode(_profileImageBase64!))
                : null,
            child: (_profileImageBase64 == null ||
                    _profileImageBase64!.isEmpty)
                ? const Icon(Icons.person,
                    size: 32, color: Colors.grey)
                : null,
          ),
        ],
      ),
    );
  }

  // ---------------- PROFILE DETAILS ----------------
  Widget _profileDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          _input("Full Name", _nameCtrl),
          _input("Email", _emailCtrl),
          _input("Phone", _phoneCtrl, readOnly: true),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: _dec("Gender"),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: _isEditable
                ? (String? v) {
                    if (v != null) setState(() => _gender = v);
                  }
                : null,
          ),
          const SizedBox(height: 16),
          if (_isEditable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: paymanBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Save Profile"),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- KYC SECTION ----------------
  Widget _kycSection() {
    if (_isKycCompleted) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Complete your KYC",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _kycRow("Aadhaar Verification", _isAadhaarVerified),
          _kycRow("PAN Verification", _isPanVerified),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycScreen()),
                );
              },
              child: const Text("Complete KYC"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kycRow(String title, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.pending,
            color: verified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            verified ? "Verified" : "Pending",
            style: TextStyle(
                color: verified ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------- KYC BADGE ----------------
  Widget _kycBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            _isKycCompleted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isKycCompleted ? Icons.verified : Icons.pending,
            size: 14,
            color: _isKycCompleted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            _isKycCompleted ? "KYC Verified" : "KYC Pending",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  _isKycCompleted ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LOGOUT ----------------
  Widget _logoutTile() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text("Logout",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      onTap: _logout,
    );
  }

  // ---------------- HELPERS ----------------
  Widget _input(String label, TextEditingController ctrl,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly || !_isEditable,
        decoration: _dec(label),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
          )
        ],
      );
}
