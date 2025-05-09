import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/aadhar_verification_screen.dart';
import 'package:paymanapp/screens/beneficiary_list_screen.dart';
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/screens/pay_out_history_screen.dart';
import 'package:paymanapp/screens/payin_history_screen.dart';
import 'package:paymanapp/screens/user_details_screen.dart';
import 'package:paymanapp/screens/users_listscreen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  final String phone;
  const UserProfileScreen({required this.phone, super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _name = 'Unknown';
  String _phone = 'N/A';
  String _InstantPayAmount = "N/A";
  String _PineLabsAmount = "N/A";
  String _userWalletAmount = "N/A";
  bool _aadharVerified = false;
  bool _isAdmin = false;
  bool _isLoading = false;
  String _CustomerType = "N/A";
  bool _payOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    getAvailableBalance();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('firstName') ?? 'Unknown';
      _phone = prefs.getString('phone') ?? 'N/A';
    });
  }

  Future<void> getAvailableBalance() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${ApiHandler.baseUri}/Auth/GetPaymanAccountAmount");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _InstantPayAmount = data['instantpayamount'];
          _PineLabsAmount = data['pinelabsamount'];
          _userWalletAmount = data['userwalletamount'];
          _aadharVerified = data['aadharverified'] == true;
          _isAdmin = data['isadmin'] == true;
          _CustomerType = data['customerType'];
          _payOut = data['isPayOut'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildListTile(IconData icon, String title, [VoidCallback? onTap]) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    String initials = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.amber,
                        child: Text(initials, style: const TextStyle(fontSize: 20, color: Colors.black)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('+91 $_phone', style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      if (_aadharVerified && _payOut)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BeneficiaryListScreen(
                                  phone: widget.phone,
                                  userWalletAmount: _userWalletAmount,
                                  pineLabsAmount: _PineLabsAmount,
                                ),
                              ),
                            );
                          },
                          child: const Text("PAYMENT", style: TextStyle(color: Colors.blueAccent)),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserDetailsScreen(
                                phone: widget.phone,
                                isAdmin: _isAdmin,
                                customerType: _CustomerType,
                              ),
                            ),
                          );
                        },
                        child: const Text("Manage", style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade900,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Image.asset("assets/images/comimage.jpg", height: 50),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Complete your profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("Get a personalised experience and easy setup", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      _aadharVerified
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Verified", style: TextStyle(color: Colors.white)),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AadharVerificationScreen(phone: widget.phone),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                              child: const Text("Get Started", style: TextStyle(color: Colors.white)),
                            ),
                    ],
                  ),
                ),
                _sectionHeader(""),
                _buildButtonRow(),
                _sectionHeader("PREFERENCES"),
                _buildListTile(Icons.language, 'Languages'),
                ...[
                  if (_isAdmin)
                    _buildListTile(Icons.group, 'Users List', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsersListScreen(phone: widget.phone, isAdmin: _isAdmin),
                        ),
                      );
                    }),
                ],
                _buildListTile(Icons.receipt_long, 'PayIn History', () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PayInHistoryScreen(phone: widget.phone),
    ),
  );
}),
_buildListTile(Icons.receipt_long, 'PayOut History', () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PayOutHistoryScreen(phone: widget.phone),
    ),
  );
}),
                _buildListTile(Icons.receipt_long, 'Bill notifications'),
                _buildListTile(Icons.tune, 'Permissions'),
                _buildListTile(Icons.color_lens, 'Theme'),
                _buildListTile(Icons.notifications, 'Reminders'),
                _sectionHeader("SECURITY"),
                _buildListTile(Icons.fingerprint, 'Biometric & screen lock'),
                _buildListTile(Icons.lock, 'Change passcode'),
                _buildListTile(Icons.block, 'Blocked accounts'),
                _buildListTile(Icons.info_outline, 'About App'),
                const Divider(color: Colors.black12),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Logout")),
                        ],
                      ),
                    );

                    if (confirm ?? false) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14, letterSpacing: 1)),
    );
  }

  Widget _buildButtonRow() {
    List<Widget> rowChildren = [];

    rowChildren.add(_amountCard("Wallet Amount", _userWalletAmount));

    if (_isAdmin) {
      rowChildren.add(const SizedBox(width: 16));
      rowChildren.add(_amountCard("PineLab Amount", _PineLabsAmount));
      rowChildren.add(const SizedBox(width: 16));
      rowChildren.add(_amountCard("InstantPay Amount", _InstantPayAmount));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: rowChildren.map((child) => Padding(padding: const EdgeInsets.only(right: 8), child: child)).toList(),
        ),
      ),
    );
  }

  Widget _amountCard(String title, String amount) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
