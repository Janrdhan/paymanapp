import 'package:flutter/material.dart';
import 'package:paymanapp/screens/HomeContainer/kyc_screen.dart';
import 'package:paymanapp/screens/Profile/user_profile_model.dart';

class KycStatusCard extends StatelessWidget {
  final UserProfile profile;
  const KycStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.name, style: const TextStyle(fontSize: 18)),
          Text(profile.phone),
          const SizedBox(height: 16),

          profile.kycStatus == "COMPLETED"
              ? const Chip(
                  label: Text("KYC Completed"),
                  backgroundColor: Colors.green,
                )
              : ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KycScreen(),
                      ),
                    );
                  },
                  child: const Text("Complete KYC"),
                ),
        ],
      ),
    );
  }
}
