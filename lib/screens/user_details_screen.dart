import 'package:flutter/material.dart';
import 'package:paymanapp/screens/new_user_details_screen.dart';

class UserDetailsScreen extends StatelessWidget {
  final String phone;
  const UserDetailsScreen({super.key,required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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

            // "ADD NEW" Button moved to top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  NewUserDetailsScreen(phone: phone)),
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
                        Text("ADD NEW", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Personal Details",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Text("Janardhan Jurra",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text("+91 9849800697", style: TextStyle(color: Colors.white)),
                            SizedBox(height: 4),
                            Text("janardhanj@nfcsolutionsusa.com",
                                style: TextStyle(color: Colors.grey)),
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

            _buildListTile("Financial Details", "Income, employment details and more"),
            _buildListTile("Additional Details", "Age, gender and more"),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text("Saved Addresses",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    );
  }
}
