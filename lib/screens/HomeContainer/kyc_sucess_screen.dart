import 'package:flutter/material.dart';

class KycSuccessScreen extends StatelessWidget {
  const KycSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.verified, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text("KYC Completed Successfully",
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
