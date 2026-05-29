import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Services/auth_service.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Summary values
  double _totalSpent = 0.0;
  int _successfulCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final token = await SessionManager.getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please login again.';
        _isLoading = false;
      });
      return;
    }

    // Format dates for API
    final start = _formatDate(_startDate);
    final end = _formatDate(_endDate);

    final transactions = await AuthService.getTransactions(
      startDate: start,
      endDate: end,
    );

    if (mounted) {
      setState(() {
        _transactions = transactions;
        _calculateSummary();
        _isLoading = false;
      });
    }
  }

  void _calculateSummary() {
    double total = 0.0;
    int success = 0;
    int pending = 0;

    for (var tx in _transactions) {
      final amount = (tx['amount'] ?? 0.0).toDouble();
      final status = tx['status'] ?? '';
      if (status.toLowerCase() == 'success') {
        total += amount;
        success++;
      } else if (status.toLowerCase() == 'pending') {
        pending++;
      }
    }

    _totalSpent = total;
    _successfulCount = success;
    _pendingCount = pending;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB), // blue
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Reports"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Select date range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Date range display
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_formatDate(_startDate)}  →  ${_formatDate(_endDate)}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                    // Summary Cards
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildSummaryCard(
                            "Total Spent",
                            "₹${_totalSpent.toStringAsFixed(2)}",
                            Colors.blue.shade50,
                            const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "Successful",
                            _successfulCount.toString(),
                            Colors.green.shade50,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "Pending",
                            _pendingCount.toString(),
                            Colors.orange.shade50,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    // Transaction List
                    Expanded(
                      child: _transactions.isEmpty
                          ? const Center(
                              child: Text(
                                'No transactions found for selected dates',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                return _buildTransactionTile(context, tx);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color bgColor, Color borderColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: borderColor)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: borderColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
    final status = tx['status'] ?? '';
    final isSuccess = status.toLowerCase() == 'success';
    final Color statusColor = isSuccess ? Colors.green : Colors.orange;
    final IconData statusIcon = isSuccess ? Icons.check_circle : Icons.pending;

    // Get icon based on transaction type (fallback)
    IconData txIcon = Icons.receipt;
    final type = (tx['type'] ?? '').toLowerCase();
    if (type.contains('mobile')) {
      txIcon = Icons.phone_android;
    } else if (type.contains('electricity')) txIcon = Icons.flash_on;
    else if (type.contains('dth')) txIcon = Icons.tv;
    else if (type.contains('credit')) txIcon = Icons.credit_card;
    else if (type.contains('money') || type.contains('transfer')) txIcon = Icons.send;

    return GestureDetector(
      onTap: () => _showTransactionDetails(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(txIcon, color: const Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['type'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    "${tx['date'] ?? ''} • ${tx['time'] ?? ''}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text("ID: ${tx['id'] ?? 'N/A'}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${(tx['amount'] ?? 0.0).toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx['type'] ?? 'Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transaction ID: ${tx['id'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Amount: ₹${(tx['amount'] ?? 0.0).toStringAsFixed(2)}"),
            Text("Date: ${tx['date'] ?? 'N/A'}"),
            Text("Time: ${tx['time'] ?? 'N/A'}"),
            Text("Status: ${tx['status'] ?? 'N/A'}"),
            if (tx['remarks'] != null) Text("Remarks: ${tx['remarks']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}