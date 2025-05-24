import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.phone,
    required this.amount,
    required this.userName,
  });

  final String phone;
  final String amount;
  final String userName;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(phone: widget.phone)),
      );
    });
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return 'XXXXXXXX${phone.substring(phone.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now();
    return Scaffold(
      backgroundColor: Color(0xFF1BB66D),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(Icons.check_circle, size: 90, color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Payment Successful",
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 6),
            Text(
              "${time.day} ${_monthName(time.month)} ${time.year} at ${_formatTime(time)}",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 30),
            _buildUserCard(),
            SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.userName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _maskPhone(widget.phone),
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "₹${widget.amount}",
                  style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  "Split Expense",
                  style: TextStyle(color: Colors.purpleAccent),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(Icons.info, "View Details"),
          _actionButton(Icons.share, "Share Receipt"),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.purple,
          radius: 24,
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white))
      ],
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
