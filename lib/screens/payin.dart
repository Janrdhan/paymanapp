import 'package:flutter/material.dart';
import 'payment_screen.dart';

class PayInScreen extends StatefulWidget {
  const PayInScreen({super.key});

  @override
  _PayInScreenState createState() => _PayInScreenState();
}

class _PayInScreenState extends State<PayInScreen> {
  final TextEditingController cardController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String selectedGateway = 'Easebuzz'; // Default gateway

  void proceedToPayment() {
    String cardNumber = cardController.text.trim();
    String mobileNumber = mobileController.text.trim();

    // ✅ Validation for empty fields
    if (cardNumber.isEmpty || mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both Card Number and Mobile Number")),
      );
      return;
    }

    // ✅ Validation for Mobile Number (10 digits, numeric)
    if (mobileNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(mobileNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid 10-digit Mobile Number")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          cardNumber: cardNumber,
          mobileNumber: mobileNumber,
          gatewayType: selectedGateway,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: cardController,
              decoration: InputDecoration(labelText: 'Card Number'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: mobileController,
              decoration: InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            Text('Gateway Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedGateway,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedGateway = newValue;
                  });
                }
              },
              items: ['Easebuzz', 'Razorpay', 'Layra'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: proceedToPayment,
                child: Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
