import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/Core/LoginAppFiles/set_pin_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/change_pin_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/forgot_pin_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/kyc_screen.dart';
import 'package:paymanapp/screens/Core/LoginAppFiles/edit_profile_screen.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class ProfileScreen extends StatefulWidget {
  final String userPhone;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userPhone,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetProfile?userPhone=${widget.userPhone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Profile data: $data");
        setState(() {
          _userData = data;
          _hasPin = data['hasPin'] ?? false;
          _isLoading = false;
        });

        // First-time user check
        if (data['isNewUser'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompleteProfileDialog();
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load profile";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error: $e";
        _isLoading = false;
      });
    }
  }

  void _showCompleteProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Welcome!"),
        content: const Text("Please complete your profile to continue."),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToEditProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text("Complete Profile"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService.logout(context);
    widget.onLogout();
  }

  void _navigateToSetPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SetPinScreen(userPhone: widget.userPhone),
      ),
    ).then((_) => _fetchUserProfile());
  }

  void _navigateToChangePin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChangePinScreen(userPhone: widget.userPhone),
      ),
    ).then((_) => _fetchUserProfile());
  }

  void _navigateToForgotPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ForgotPinScreen(userPhone: widget.userPhone),
      ),
    ).then((_) => _fetchUserProfile());
  }

  void _navigateToKyc() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const KycScreen(),
      ),
    ).then((_) => _fetchUserProfile());
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditProfileScreen(
          userPhone: widget.userPhone,
          userData: _userData,
        ),
      ),
    ).then((_) => _fetchUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: const Text("Profile"),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserProfile,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final String userName = _userData['name'] ?? "User ${widget.userPhone.substring(widget.userPhone.length - 4)}";
    final String email = _userData['email'] ?? "Not provided";
    final String kycStatus = _userData['kycStatus'] ?? "Pending";
    final bool isKycComplete = kycStatus.toLowerCase() == "verified";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar & name
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isKycComplete ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "KYC $kycStatus",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const Divider(height: 0, thickness: 1),
                  ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFF2563EB)),
                    title: const Text("Email"),
                    subtitle: Text(email),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _navigateToEditProfile,
                    ),
                  ),
                  const Divider(height: 0, indent: 60),
                  ListTile(
                    leading: const Icon(Icons.security, color: Color(0xFF2563EB)),
                    title: const Text("KYC Status"),
                    subtitle: Text(kycStatus),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: _navigateToKyc,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PIN Management card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Security",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const Divider(height: 0, thickness: 1),
                  if (!_hasPin)
                    ListTile(
                      leading: const Icon(Icons.lock_open, color: Colors.orange),
                      title: const Text("Set PIN"),
                      subtitle: const Text("Secure your account with a 6-digit PIN"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _navigateToSetPin,
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.lock, color: Color(0xFF2563EB)),
                      title: const Text("Change PIN"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _navigateToChangePin,
                    ),
                    const Divider(height: 0, indent: 60),
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Colors.red),
                      title: const Text("Forgot PIN?"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _navigateToForgotPin,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}