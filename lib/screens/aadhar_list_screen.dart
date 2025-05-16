import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class AadharListScreen extends StatefulWidget {
  final String phone;
  const AadharListScreen({required this.phone, super.key});

  @override
  State<AadharListScreen> createState() => _AadharListScreenState();
}

class _AadharListScreenState extends State<AadharListScreen> {
  List<AadharData> _aadharList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAadharList();
  }

  Future<void> _fetchAadharList() async {
    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/GetAadharList');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _aadharList = data.map((e) => AadharData.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load Aadhar list: $e")),
      );
    }
  }

  Uint8List _safeDecodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return Uint8List(0);
    try {
      return base64Decode(base64String);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _buildImageTile(String label, Uint8List imageBytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageBytes.isEmpty
              ? const Center(child: Text("No Image"))
              : Image.memory(imageBytes, fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Aadhar List"),
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
      elevation: 0,),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _aadharList.isEmpty
              ? const Center(child: Text("No Aadhar data found."))
              : ListView.builder(
                  itemCount: _aadharList.length,
                  itemBuilder: (context, index) {
                    final item = _aadharList[index];
                    Uint8List frontImage = _safeDecodeImage(item.aadharFront);
                    Uint8List backImage = _safeDecodeImage(item.aadharBack);

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            Text("Aadhar: ${item.aadharNumber}"),
                            Text("PAN: ${item.panNumber}"),
                            const SizedBox(height: 25),
                            _buildImageTile("Aadhar Front", frontImage),
                            _buildImageTile("Aadhar Back", backImage)
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AadharData {
  final String name;
  final String aadharNumber;
  final String panNumber;
  final String aadharFront;
  final String aadharBack;

  AadharData({
    required this.name,
    required this.aadharNumber,
    required this.panNumber,
    required this.aadharFront,
    required this.aadharBack
  });

  factory AadharData.fromJson(Map<String, dynamic> json) {
    return AadharData(
      name: json['name'] ?? '',
      aadharNumber: json['aadharNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      aadharFront: json['aadharFront'] ?? '',
      aadharBack: json['aadharBack'] ?? ''
    );
  }
}
