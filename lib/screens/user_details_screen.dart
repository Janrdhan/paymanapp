import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/new_user_details_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class UserDetailsScreen extends StatefulWidget {
  final String phone;
  final bool isAdmin;
  final String customerType;

  const UserDetailsScreen({
    super.key,
    required this.phone,
    required this.isAdmin,
    required this.customerType,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  bool isAdmin = false;
  String customerType = '';

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/GetUserDetails');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userDetails = data;
          isAdmin = userDetails!['isAdmin'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Failed to load user details');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDistributor = widget.customerType.trim().toLowerCase() == 'distributor';
    print("Customer Type: '${widget.customerType}' => isDistributor: $isDistributor");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.deepPurple.shade100,
                    height: 160,
                    width: double.infinity,
                    child: const Center(
                      child: Icon(Icons.person, size: 70, color: Colors.white),
                    ),
                  ),
                  if (isDistributor)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewUserDetailsScreen(
                                phone: widget.phone,
                                isAdmin: isAdmin,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.add, color: Colors.blueAccent),
                                Text(
                                  "ADD NEW",
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (userDetails != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Personal Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      userDetails!['name'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "+91 ${userDetails!['phone'] ?? ''}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userDetails!['email'] ?? '',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Address: ${userDetails!['address'] ?? ''}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.edit, color: Colors.grey.shade400),
                                  const SizedBox(height: 20),
                                  const Icon(Icons.verified, color: Colors.green),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
