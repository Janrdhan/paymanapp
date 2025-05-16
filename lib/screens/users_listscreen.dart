import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/new_user_details_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class UsersListScreen extends StatefulWidget {
  final String phone;
  final bool isAdmin;
  const UsersListScreen({super.key, required this.phone, required this.isAdmin});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final url = Uri.parse("${ApiHandler.baseUri1}/Users/GetAllUsers");
      final response = await http.get(url);

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['users'] is List) {
        setState(() {
          _users = data['users'];
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load users");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBoolCheckbox(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: null),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text("Users List"),
        elevation: 0,
        ),
      backgroundColor: Colors.white, // Set background color here
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${user['phone'] ?? ''}"),
                        Text("Email: ${user['email'] ?? ''}"),
                        Text("Customer Type: ${user['customerType'] ?? ''}"),
                        Text("Margin: ${user['margin']?.toString() ?? ''}"),
                        Text("Status: ${user['isActive'] ?? ''}"),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _buildBoolCheckbox("PayIn", user['payIn'] == true),
                            _buildBoolCheckbox("PayOut", user['payOut'] == true),
                            _buildBoolCheckbox("CCBill", user['ccBill'] == true),
                            _buildBoolCheckbox("Aadhar", user['isAadherVerified'] == true),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewUserDetailsScreen(
                            phone: widget.phone,
                            isAdmin: widget.isAdmin,
                            userData: user,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
