import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // your dashboard screen import

class PaymentSuccessScreen extends StatefulWidget {
  final String phone;
  final String amount;
  final String userName;
   final String customerType;


  const PaymentSuccessScreen({
    super.key,
    required this.phone,
    required this.amount,
    required this.userName,
    required this.customerType
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    if(widget.customerType == 'new'){
       // Play success sound
   _playSuccessSoundNONMob();
    }else{
 _playSuccessSound();
    }

 
    // Auto-redirect to dashboard after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _goToDashboard();
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success-340660.mp3'));
    } catch (e) {
      print("Error playing success sound: $e");
    }
  }

   Future<void> _playSuccessSoundNONMob() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/BharatConnect MOGO 270824.mp3'));
    } catch (e) {
      print("Error playing success sound: $e");
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(phone: widget.phone),
      ),
      (Route<dynamic> route) => false, // removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToDashboard(); // force navigation to dashboard on back press
        return false; // prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Payment Successful",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("Amount: ₹${widget.amount}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _goToDashboard, // navigate and clear stack
                child: const Text("Go to Dashboard"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
