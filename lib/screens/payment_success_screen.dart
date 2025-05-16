import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
   const PaymentSuccessScreen({
    super.key,
    required this.phone
  });
   final String phone;
  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSuccessSound();
    _navigateToDashboard();
  }

  Future<void> _playSuccessSound() async {
    await _audioPlayer.play(AssetSource('sounds/success-340660.mp3'));
  }

  void _navigateToDashboard() {
    Future.delayed(Duration(seconds: 5), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(phone: widget.phone,)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now();
    return Scaffold(
      backgroundColor: Color(0xFF388E3C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Payment Successful",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              "${time.day} ${_monthName(time.month)} ${time.year} at ${_formatTime(time)}",
              style: TextStyle(color: Colors.white70),
            )
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
