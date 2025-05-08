import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/new_user_details_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
//import 'user_edit_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users List")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['firstName'] ?? 'No Name'),
                  subtitle: Text(user['phone'] ?? 'No Phone'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewUserDetailsScreen(phone: widget.phone,isAdmin: widget.isAdmin,userData: user),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
