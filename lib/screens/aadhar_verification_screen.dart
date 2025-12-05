import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class AadharVerificationScreen extends StatefulWidget {
  final String phone;
  final String customerType;
  const AadharVerificationScreen({required this.phone,required this.customerType ,super.key});

  @override
  State<AadharVerificationScreen> createState() => _AadharVerificationScreenState();
}

class _AadharVerificationScreenState extends State<AadharVerificationScreen> {
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _panCardController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  final String _customerType = "N/A";

  XFile? _aadharFrontImage;
  XFile? _aadharBackImage;
  XFile? _panCardImage;

  String? _refId;

  final String baseUrl = "${ApiHandler.baseUri}/Auth";

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'aadharFront':
            _aadharFrontImage = pickedFile;
            break;
          case 'aadharBack':
            _aadharBackImage = pickedFile;
            break;
          case 'panCard':
            _panCardImage = pickedFile;
            break;
        }
      });
    }
  }

  Future<String?> _encodeImage(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // Send OTP API call
  Future<void> sendOtp() async {
    final aadharNumber = _aadharController.text.trim();

    if (aadharNumber.isEmpty || aadharNumber.length != 12) {
      _showMessage("Please enter a valid 12-digit Aadhar number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("widget.phone: ${widget.phone}");
      final url = Uri.parse("${ApiHandler.baseUri}/Auth/AdharNumberVerify1"); // Replace with actual API URL

      // Ensure the payload is formatted correctly
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"AdharNumber": aadharNumber,"phone": widget.phone}),
      );

      // Log the status code and response body for debugging
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isOtpSent = true;
          print("Response refid: ${data['refid']}");
          _refId = data['refid'];
        });
        _showMessage("OTP sent to your Aadhar linked mobile.");
      } else {
        _showMessage(data['message'] ?? "Failed to send OTP. Please try again.");
      }
    } catch (e) {
      print("Error: $e");  // Log the error for debugging
      _showMessage("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verify OTP API call
 Future<void> verifyOtp() async {
  final otp = _otpController.text.trim();

  if (otp.isEmpty || otp.length != 6) {
    _showMessage("Please enter a valid 6-digit OTP.");
    return;
  }

  setState(() => _isLoading = true);

  try {
    print("Response refid: $_refId");
    final url = Uri.parse('${ApiHandler.baseUri}/Auth/VerifyAdharOTP');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refId": _refId, "otp": otp, "phone": widget.phone}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        _isOtpVerified = true;
      });

      _showMessage("OTP verified successfully.");

      // 🚀 If customerType == "new", go directly to Dashboard
      if (widget.customerType.toLowerCase() == "new") {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(phone: widget.phone),
            ),
          );
        });
        return; // stop here, don’t show document upload
      }
    } else {
      _showMessage(data['message'] ?? "Failed to verify OTP. Please try again.");
    }
  } catch (e) {
    _showMessage("Something went wrong. Please try again.");
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> uploadDocuments() async {
    if (!_isOtpVerified) {
      _showMessage("Verify OTP first.");
      return;
    }

    final aadharFrontBase64 = await _encodeImage(_aadharFrontImage);
    final aadharBackBase64 = await _encodeImage(_aadharBackImage);
    final panCardBase64 = await _encodeImage(_panCardImage);
    final panNumber = _panCardController.text.trim();

    if ([aadharFrontBase64, aadharBackBase64, panCardBase64, panNumber].contains(null) || panNumber.isEmpty) {
      _showMessage("All fields and images are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/UploadDocuments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AadharFront': aadharFrontBase64,
          'AadharBack': aadharBackBase64,
          'PanCard': panCardBase64,
          'PanCardNumber': panNumber,
          "phone": widget.phone
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _showMessage("Documents uploaded successfully.");
        // Wait for the snackbar to show, then navigate
  Future.delayed(const Duration(seconds: 1), () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  DashboardScreen(phone: widget.phone)),
    );
  });
      } else {
        _showMessage(data['message'] ?? "Failed to upload.");
      }
    } catch (e) {
      _showMessage("Error uploading documents.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aadhar Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _aadharController,
              decoration: const InputDecoration(labelText: "Aadhar Number"),
              keyboardType: TextInputType.number,
              maxLength: 12,
            ),
            ElevatedButton(
              onPressed: _isOtpSent ? null : sendOtp,
              child: const Text("Send OTP"),
            ),
            if (_isOtpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "OTP"),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              ElevatedButton(
                onPressed: _isOtpVerified ? null : verifyOtp,
                child: const Text("Verify OTP"),
              ),
            ],
            if (_isOtpVerified) ...[
  // Show PAN + Docs only if NOT "new"
  if (widget.customerType.toLowerCase() != "new") ...[
    TextField(
      controller: _panCardController,
      decoration: const InputDecoration(labelText: "PAN Card Number"),
    ),
    ElevatedButton(
      onPressed: () => _pickImage('aadharFront'),
      child: Text(_aadharFrontImage != null ? "Aadhar Front ✅" : "Upload Aadhar Front"),
    ),
    ElevatedButton(
      onPressed: () => _pickImage('aadharBack'),
      child: Text(_aadharBackImage != null ? "Aadhar Back ✅" : "Upload Aadhar Back"),
    ),
    ElevatedButton(
      onPressed: () => _pickImage('panCard'),
      child: Text(_panCardImage != null ? "PAN Card ✅" : "Upload PAN Card"),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: uploadDocuments,
      child: const Text("Upload All Documents"),
    ),
  ],
],
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
