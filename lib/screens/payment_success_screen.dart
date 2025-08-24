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
  bool _navigated = false; // prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _playSuccessSound();
    _navigateToDashboard(); // auto after 5 seconds
  }

  Future<void> _playSuccessSound() async {
    await _audioPlayer.play(AssetSource('sounds/success-340660.mp3'));
  }

  void _navigateToDashboard({bool immediate = false}) {
    if (_navigated) return; // avoid duplicate navigation
    _navigated = true;

    if (immediate) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(phone: widget.phone),
        ),
      );
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(phone: widget.phone),
            ),
          );
        }
      });
    }
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return 'XXXXXXXX${phone.substring(phone.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now();
    return WillPopScope(
      onWillPop: () async {
        _navigateToDashboard(immediate: true); // go to dashboard immediately
        return false; // prevent default back pop
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1BB66D),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle, size: 90, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                "Payment Successful",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                "${time.day} ${_monthName(time.month)} ${time.year} at ${_formatTime(time)}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 30),
              _buildUserCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.userName.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _maskPhone(widget.phone),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "₹${widget.amount}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text(
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
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white))
      ],
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  static String _formatTime(DateTime time) {
    int hour = time.hour;
    String meridiem = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $meridiem";
  }
}
