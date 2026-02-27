import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/Core/app_colors.dart';
import 'package:paymanapp/screens/HomeContainer/kyc_screen.dart';
import 'package:paymanapp/screens/LogIn/login_screen.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _isEditable = false;
  bool _isKycCompleted = false;

  String? _profileBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /* ================= LOAD PROFILE ================= */

  Future<void> _loadProfile() async {
    final token = await SessionManager.getToken();
    final phone = await SessionManager.getPhone();

    if (phone == null) {
      setState(() => _loading = false);
      return;
    }

    _phoneCtrl.text = phone;

    final res = await http.post(
      Uri.parse('${ApiHandler.baseUri1}/profile/GetProfile'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"phone": phone}),
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        _nameCtrl.text = data["name"] ?? "";
        _emailCtrl.text = data["email"] ?? "";
        _profileBase64 =
            (data["profileImageBase64"] ?? "").toString().trim();
        _isKycCompleted = data["isKycCompleted"] == true;

        /// ✅ AUTO EDIT IF DATA EMPTY
        _isEditable =
            _nameCtrl.text.trim().isEmpty ||
            _emailCtrl.text.trim().isEmpty;

        _loading = false;
      });
    }
  }

  /* ================= PROFILE PHOTO ================= */

  Future<void> _pickProfilePhoto() async {
    if (!_isEditable) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();
    setState(() => _profileBase64 = base64Encode(bytes));
  }

  /* ================= SAVE PROFILE ================= */

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Email required")),
      );
      return;
    }

    if (_profileBase64 == null || _profileBase64!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload profile photo")),
      );
      return;
    }

    final token = await SessionManager.getToken();

    await http.post(
      Uri.parse('${ApiHandler.baseUri1}/profile/UpdateProfile'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "profileImageBase64": _profileBase64,
      }),
    );

    if (!mounted) return;

    setState(() => _isEditable = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  /* ================= LOGOUT ================= */

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (_nameCtrl.text.trim().isNotEmpty &&
              _emailCtrl.text.trim().isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _isEditable = !_isEditable);
              },
              child: Text(
                _isEditable ? "Cancel" : "Edit",
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _profileHeader(),
                  const SizedBox(height: 16),

                  _kycStatusCard(),

                  _field("Name", _nameCtrl, enabled: _isEditable),
                  _field("Email", _emailCtrl, enabled: _isEditable),
                  _field("Phone", _phoneCtrl, enabled: false),

                  if (_isEditable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Save Profile"),
                      ),
                    ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /* ================= HEADER ================= */

  Widget _profileHeader() {
    ImageProvider? image;

    if (_profileBase64 != null && _profileBase64!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(_profileBase64!));
      } catch (_) {
        image = null;
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfilePhoto,
          child: CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.primary,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person,
                    size: 42, color: Colors.white)
                : null,
          ),
        ),
        if (_isEditable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Tap to change profile photo",
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /* ================= KYC ================= */

  Widget _kycStatusCard() {
    if (_isKycCompleted) {
      return _statusCard(
        Icons.verified,
        Colors.green,
        "KYC Completed\nYour account is verified",
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "KYC not completed\nComplete KYC to unlock all services",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final done = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycScreen()),
              );
              if (done == true) _loadProfile();
            },
            child: const Text("Complete"),
          )
        ],
      ),
    );
  }

  Widget _statusCard(IconData icon, Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= FIELD ================= */

  Widget _field(String label, TextEditingController ctrl,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
