import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class WalletScreen extends StatefulWidget {
  final String userPhone;
  const WalletScreen({super.key, required this.userPhone});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _balance = 0.0;
  bool _isLoadingOverall = true; // Single master loader
  
  List<Map<String, dynamic>> _payInTransactions = [];
  List<Map<String, dynamic>> _payoutTransactions = [];
  List<Map<String, dynamic>> _passbookEntries = [];
  
  
  String _errorMessage = '';
  String _searchQuery = '';
  
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoadingOverall = true);
    try {
      // Run all four requests in parallel
      await Future.wait([
        _fetchBalance(),
        _fetchPayInTransactions(),
        _fetchPayoutTransactions(),
        _fetchPassbook(),
      ]);
      if (mounted) setState(() => _isLoadingOverall = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wallet data: $e';
        _isLoadingOverall = false;
      });
    }
  }

  // ------------------- BALANCE -------------------
  Future<void> _fetchBalance() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetBalance?userPhone=${widget.userPhone}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        double bal = 0.0;
        if (data.containsKey('balance')) {
          final value = data['balance'];
          bal = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
        } else if (data.containsKey('Balance')) {
          final value = data['Balance'];
          bal = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
        }
        if (mounted) setState(() => _balance = bal);
      }
    } catch (e) {
      print('Balance error: $e');
    }
  }

  // ------------------- PAY IN -------------------
  Future<void> _fetchPayInTransactions() async {
    try {
      final start = DateFormat('yyyy-MM-dd').format(_dateRange.start);
      final end = DateFormat('yyyy-MM-dd').format(_dateRange.end);
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetPayInTransactions'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userPhone': widget.userPhone,
          'startDate': start,
          'endDate': end,
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _payInTransactions = data.map((tx) {
              DateTime txDate;
              try {
                txDate = DateTime.parse(tx['transectionDate'] ?? '').toLocal();
              } catch (e) {
                txDate = DateTime.now();
              }
              return {
                'amount': (tx['amount'] ?? 0).toDouble(),
                'date': txDate,
                'status': (tx['status'] == true) ? 'Success' : 'Failed',
                'description': tx['cardNumber'] ?? 'UPI Add Money',
                'transactionId': tx['transectionId'] ?? '',
                'commission': (tx['commission'] ?? 0).toDouble(),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('PayIn error: $e');
    }
  }

  // ------------------- PAY OUT -------------------
  Future<void> _fetchPayoutTransactions() async {
    try {
      final start = DateFormat('yyyy-MM-dd').format(_dateRange.start);
      final end = DateFormat('yyyy-MM-dd').format(_dateRange.end);
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetPayOutTransactions'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({  
          'userPhone': widget.userPhone,
          'startDate': start,
          'endDate': end,
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _payoutTransactions = data.map((tx) {
              DateTime txDate;
              try {
                txDate = DateTime.parse(tx['transectionDate'] ?? '').toLocal();
              } catch (e) {
                txDate = DateTime.now();
              }
              return {
                'amount': (tx['amount'] ?? 0).toDouble(),
                'date': txDate,
                'status': (tx['status'] == true) ? 'Success' : 'Failed',
                'description': tx['accountHolder'] ?? 'Bill Payment',
                'transactionId': tx['transectionId'] ?? '',
                'commission': (tx['commission'] ?? 0).toDouble(),
                'payOutType': tx['payOutType'] ?? '',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Payout error: $e');
    }
  }

  // ------------------- PASSBOOK -------------------
  Future<void> _fetchPassbook() async {
    try {
      final start = DateFormat('yyyy-MM-dd').format(_dateRange.start);
      final end = DateFormat('yyyy-MM-dd').format(_dateRange.end);
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetPassbook'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userPhone': widget.userPhone,
          'startDate': start,
          'endDate': end,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> transactions = data['transactions'] ?? [];
        if (mounted) {
          setState(() {
            _passbookEntries = transactions.map((entry) {
              DateTime entryDate;
              try {
                entryDate = DateTime.parse(entry['dateTime'] ?? '').toLocal();
              } catch (e) {
                entryDate = DateTime.now();
              }
              final amount = (entry['amount'] ?? 0).toDouble();
              final isCredit = entry['isCredit'] ?? false;
              return {
                'date': entryDate,
                'credit': isCredit ? amount : 0.0,
                'debit': isCredit ? 0.0 : amount,
                'balance': (entry['availableBalance'] ?? 0).toDouble(),
                'remarks': entry['details'] ?? '',
                'status': entry['status'] ?? 'Success',
                'isCredit': isCredit,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Passbook error: $e');
    }
  }

  // ------------------- SEARCH & FILTER -------------------
  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list, String field) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) => item[field].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _updateSearch(String query) => setState(() => _searchQuery = query);

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      await _fetchWalletData();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _dateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
    });
    _fetchWalletData();
  }

  // ------------------- EXPORT -------------------
  Future<void> _exportCSV(String type, List<Map<String, dynamic>> data, List<String> headers, List<String> fields) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export only on mobile')));
      return;
    }
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    final rows = [headers];
    for (var item in data) {
      rows.add(fields.map((f) => item[f]?.toString() ?? '').toList());
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${type}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported $type');
  }

  Future<void> _exportPDF(String type, List<Map<String, dynamic>> data, List<String> headers, List<String> fields) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export only on mobile')));
      return;
    }
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    final pdf = pw.Document();
    final rows = data.map((item) => fields.map((f) => item[f]?.toString() ?? '').toList()).toList();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('$type Transactions', style: const pw.TextStyle(fontSize: 20))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(headers: headers, data: rows, border: pw.TableBorder.all()),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${type}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Exported $type');
  }

  // ------------------- ADD MONEY -------------------
  Future<void> _addMoney() async {
    final amountController = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Money to Wallet"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter amount", prefixText: "₹ ", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) Navigator.pop(ctx, amount);
              else ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Valid amount")));
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      // Show overall loader again
      setState(() => _isLoadingOverall = true);
      try {
        final res = await http.post(
          Uri.parse('${ApiHandler.baseUri}/Wallet/AddMoney'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"userPhone": widget.userPhone, "amount": result}),
        );
        if (res.statusCode == 200) {
          await _fetchWalletData(); // This will set overall loading to false when done
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("₹$result added!")));
        } else throw Exception('Add money failed');
      } catch (e) {
        setState(() => _isLoadingOverall = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    // Show full‑screen loader while fetching initial data
    if (_isLoadingOverall) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(title: const Text("Payman Wallet"), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Payman Wallet")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchWalletData, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Payman Wallet"),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: _selectDateRange, tooltip: 'Date range'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWalletData, tooltip: 'Refresh'),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _updateSearch,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close), onPressed: _resetFilters, tooltip: 'Reset'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2563EB),
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: "PayIn"), Tab(text: "Payout"), Tab(text: "Passbook")],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPayInTab(),
                _buildPayoutTab(),
                _buildPassbookTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMoney,
        icon: const Icon(Icons.add),
        label: const Text("Add Money"),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          // Once overall loading is false, balance is already loaded → no loader here
          // We'll show balance directly (it's already set)
          Text("₹ ${_balance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text("UPI • Wallet • Bank Transfer", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // These tab builders no longer have their own loading indicators because
  // initial data is already present. For refresh / filter they can be enabled,
  // but for simplicity we assume data is always there after initial load.
  Widget _buildPayInTab() {
    final data = _filterList(_payInTransactions, 'description');
    if (data.isEmpty) return const Center(child: Text("No PayIn transactions"));
    return _buildListWithExport(data, 'PayIn', isPayIn: true);
  }

  Widget _buildPayoutTab() {
    final data = _filterList(_payoutTransactions, 'description');
    if (data.isEmpty) return const Center(child: Text("No Payout transactions"));
    return _buildListWithExport(data, 'Payout', isPayIn: false);
  }

  Widget _buildPassbookTab() {
    final data = _filterList(_passbookEntries, 'remarks');
    if (data.isEmpty) return const Center(child: Text("No passbook entries"));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.grid_on, color: Color(0xFF2563EB)),
              onPressed: () => _exportCSV('Passbook', data, ['Date', 'Remarks', 'Credit', 'Debit', 'Balance'], ['date', 'remarks', 'credit', 'debit', 'balance']),
              tooltip: 'CSV',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _exportPDF('Passbook', data, ['Date', 'Remarks', 'Credit', 'Debit', 'Balance'], ['date', 'remarks', 'credit', 'debit', 'balance']),
              tooltip: 'PDF',
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final e = data[index];
              final isCredit = e['isCredit'] ?? false;
              final amount = isCredit ? e['credit'] : e['debit'];
              final date = DateFormat('dd MMM yyyy').format(e['date'] as DateTime);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isCredit ? Colors.green : Colors.red).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['remarks'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isCredit ? '+' : '-'} ₹$amount",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text("Bal: ₹${e['balance']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListWithExport(List<Map<String, dynamic>> data, String type, {required bool isPayIn}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.grid_on, color: Color(0xFF2563EB)),
              onPressed: () => _exportCSV(type, data, ['Date', 'Description', 'Amount', 'Status'], ['date', 'description', 'amount', 'status']),
              tooltip: 'CSV',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _exportPDF(type, data, ['Date', 'Description', 'Amount', 'Status'], ['date', 'description', 'amount', 'status']),
              tooltip: 'PDF',
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final tx = data[index];
              final date = DateFormat('dd MMM yyyy').format(tx['date'] as DateTime);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPayIn ? Colors.green : Colors.red).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isPayIn ? Icons.download : Icons.upload, color: isPayIn ? Colors.green : Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['description'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (tx['status'] != 'Success')
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text(tx['status'], style: const TextStyle(fontSize: 10, color: Colors.orange)),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "${isPayIn ? '+' : '-'} ₹${tx['amount']}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPayIn ? Colors.green : Colors.black87),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}