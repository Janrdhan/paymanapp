import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // your dashboard screen import

class PaymentSuccessScreen extends StatefulWidget {
  final String phone;
  final String amount;
  final String userName;
  final String customerType;

  const PaymentSuccessScreen({
    Key? key,
    required this.phone,
    required this.amount,
    required this.userName,
    required this.customerType
  }) : super(key: key);

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
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "CONFIRMATION PAGE",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/B Assured Logo_PNG.png', // replace with your PNG path
                width: 200,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 89, 115, 126),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "PAYMENT SUCCESSFUL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _goToDashboard, // navigate and clear stack
                child: const Text("Go to Dashboard"),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
