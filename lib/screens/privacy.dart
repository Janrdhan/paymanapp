import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Policy"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "This privacy policy (“Policy”) relates to the manner PAYMAN FINTECH SOLUTIONS PVT LTD (“we”, “us”, “our”) in which we use, handle and process the data that you provide us in connection with using the products or services we offer. By using this website or by availing goods or services offered by us, you agree to the terms and conditions of this Policy, and consent to our use of your data.",
            ),
            SizedBox(height: 10),
            Text(
              "We are committed to ensuring that your privacy is protected in accordance with applicable laws and regulations. We urge you to acquaint yourself with this Policy to familiarize yourself with the manner in which your data is being handled by us.",
            ),
            SizedBox(height: 10),
            Text(
              "What Data is Being Collected:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text("We may collect the following information from you:"),
            SizedBox(height: 5),
            BulletPoint("Name"),
            BulletPoint("Contact information including address and email address"),
            BulletPoint("Demographic information or, preferences or interests"),
            BulletPoint("Personal Data or Other information relevant/required for providing the goods or services to you"),
            SizedBox(height: 10),
            Text(
              "How We Use Your Data:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            BulletPoint("For internal record keeping"),
            BulletPoint("For improving our products or services"),
            BulletPoint("For providing updates regarding our products or services including special offers"),
            BulletPoint("To communicate information to you"),
            BulletPoint("For internal training and quality assurance purposes"),
            SizedBox(height: 10),
            Text(
              "Who Do We Share Your Data With:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            BulletPoint("Third parties including service providers for order fulfillment and business operations"),
            BulletPoint("Group companies where relevant"),
            BulletPoint("Auditors or advisors where required"),
            BulletPoint("Government, regulatory, or law enforcement authorities as per legal obligations"),
            SizedBox(height: 10),
            Text(
              "Your Rights:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            BulletPoint("Right to review and correct data"),
            BulletPoint("Right to withdraw consent (which may affect service availability)"),
            SizedBox(height: 10),
            Text(
              "Data Retention:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("We may retain your data as long as required for business and legal purposes."),
            SizedBox(height: 10),
            Text(
              "Contact Us:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("For any queries, please contact: ajaykusa225@gmail.com"),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint(this.text, {super.key});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
