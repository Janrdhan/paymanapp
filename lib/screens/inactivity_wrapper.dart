import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _inactivityTimer;
  Timer? _dialogTimer;

  @override
  void initState() {
    super.initState();
    _loadPhone();
    _resetInactivityTimer();
  }

  void _loadPhone() async {
    setState(() {
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), _showInactivityDialog);
  }

  void _showInactivityDialog() async {
    _dialogTimer = Timer(const Duration(seconds: 10), () {
      Navigator.of(context).pop(); // close dialog
      _logout();
    });

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Timeout"),
        content: const Text("You’ve been inactive for 5 minute. Log out?"),
        actions: [
          TextButton(
            onPressed: () {
              _dialogTimer?.cancel();
              Navigator.of(context).pop(false); // Stay logged in
            },
            child: const Text("Stay Logged In"),
          ),
          TextButton(
            onPressed: () {
              _dialogTimer?.cancel();
              Navigator.of(context).pop(true); // Confirm logout
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (result == true) {
      _logout();
    } else {
      _resetInactivityTimer();
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear(); // Uncomment this if needed
    final storedPhone = prefs.getString('phone') ?? 'N/A';
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen(phone: storedPhone)),
        (_) => false,
      );
    }
  }

  void _handleUserInteraction([_]) => _resetInactivityTimer();

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _dialogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
