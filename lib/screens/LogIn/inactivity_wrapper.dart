import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paymanapp/screens/LogIn/login_screen.dart';
import '../services/session_manager.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(minutes: 5), _logout);
  }

  void _logout() async {
    //await SessionManager.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
