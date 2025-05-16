import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';

class PaymentFailureScreen extends StatefulWidget {
  const PaymentFailureScreen({
    super.key,
    required this.phone,
  });

  final String phone;

  @override
  _PaymentFailureScreenState createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playFailureSound();
    _navigateToDashboard();
  }

  Future<void> _playFailureSound() async {
    await _audioPlayer.play(AssetSource('sounds/success-340660.mp3')); // Add your own failure sound file here
  }

  void _navigateToDashboard() {
    Future.delayed(Duration(seconds: 5), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(phone: widget.phone),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now();
    return Scaffold(
      backgroundColor: Color(0xFFD32F2F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Payment Failed",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "${time.day} ${_monthName(time.month)} ${time.year} at ${_formatTime(time)}",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String meridiem = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $meridiem";
  }
}
