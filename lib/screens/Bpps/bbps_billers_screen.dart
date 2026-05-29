import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'bbps_fetch_screen.dart';

class BBPSBillersScreen extends StatefulWidget {
  final String category;
  final String userPhone;

  const BBPSBillersScreen({
    super.key,
    required this.category,
    required this.userPhone,
  });

  @override
  State<BBPSBillersScreen> createState() => _BBPSBillersScreenState();
}

class _BBPSBillersScreenState extends State<BBPSBillersScreen> {
  List<Map<String, dynamic>> _allBillers = [];
  List<Map<String, dynamic>> _filteredBillers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBillers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBillers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final uri = Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
          .replace(queryParameters: {
        "billerName": widget.category,
        "userPhone": widget.userPhone,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> billersList = data["billers"] ?? [];
        setState(() {
          _allBillers = billersList.map((e) => Map<String, dynamic>.from(e)).toList();
          _filteredBillers = _allBillers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load billers (${res.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error: $e";
        _isLoading = false;
      });
    }
  }

  void _filterBillers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBillers = _allBillers;
      } else {
        _filteredBillers = _allBillers.where((biller) {
          final name = biller['billerName']?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(widget.category),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Gradient header
          _buildHeaderCard(),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search billers...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _filterBillers,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Choose your biller",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchBillers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredBillers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No billers found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredBillers.length,
      itemBuilder: (context, index) {
        final biller = _filteredBillers[index];
        final iconUrl = biller['iconUrl'] ?? '';
        final hasValidIcon = iconUrl.isNotEmpty && iconUrl.startsWith('http');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: hasValidIcon
                  ? ClipOval(
                      child: Image.network(
                        iconUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.receipt, color: const Color(0xFF2563EB), size: 24),
                      ),
                    )
                  : Icon(Icons.receipt, color: const Color(0xFF2563EB), size: 24),
            ),
            title: Text(
              biller['billerName'] ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              biller['category'] ?? widget.category,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BBPSFetchScreen(
                  biller: biller,
                  userPhone: widget.userPhone,
                  category: widget.category,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}