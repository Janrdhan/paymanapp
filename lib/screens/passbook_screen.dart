import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:paymanapp/widgets/api_handler.dart';

class PassBook extends StatefulWidget {
  final String phone;
  const PassBook({super.key, required this.phone});

  @override
  State<PassBook> createState() => _PassBookState();
}

class _PassBookState extends State<PassBook> {
  late Future<PassbookData> futurePassbook;
  DateTimeRange? selectedDateRange;
  int currentPage = 0;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    fetchData();
  }

  void fetchData() {
    futurePassbook = fetchPassBook(
      widget.phone,
      selectedDateRange!.start,
      selectedDateRange!.end,
    );
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        currentPage = 0;
      });
      fetchData();
    }
  }

 // *** PDF download function ***
  Future<void> downloadPdf(PassbookData data) async {
  final pdf = pw.Document();

  // Load font from assets
  final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: ttf),
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Passbook Statement')),
        pw.Paragraph(text: 'User: ${data.user.name}'),
        pw.Paragraph(text: 'Phone: ${data.user.phone}'),
        pw.Paragraph(text: 'Email: ${data.user.email}'),
        pw.Table.fromTextArray(
          headers: [
            'Date & Time',
            'Details',
            'Account',
            'Amount',
            'Balance'
          ],
          data: data.transactions.map((txn) {
            final dt = DateTime.parse(txn.dateTime);
            return [
              '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}',
              txn.details,
              txn.accountName,
              '${txn.isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(2)}',
              '₹${txn.availableBalance.toStringAsFixed(2)}',
            ];
          }).toList(),
        ),
      ],
    ),
  );

  final pdfBytes = await pdf.save();

  final fileName = 'passbook_${DateTime.now().millisecondsSinceEpoch}.pdf';

 
    // Mobile (Android/iOS): save in app document directory silently
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${file.path}')),
    );
  
}



  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("d MMM''yy");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pass Book - PAYMAN'),
        actions: [
          IconButton(onPressed: pickDateRange, icon: const Icon(Icons.date_range))
        ],
      ),
      // floatingActionButton: FutureBuilder<PassbookData>(
      //   future: futurePassbook,
      //   builder: (context, snapshot) {
      //     if (snapshot.hasData && snapshot.data!.transactions.isNotEmpty) {
      //       return FloatingActionButton.extended(
      //         icon: const Icon(Icons.picture_as_pdf),
      //         label: const Text('Download PDF'),
      //         onPressed: () => downloadPdf(snapshot.data!),
      //       );
      //     }
      //     return const SizedBox.shrink();
      //   },
      // ),
      body: FutureBuilder<PassbookData>(
        future: futurePassbook,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          final data = snapshot.data!;
          final startIndex = currentPage * 10;
          final endIndex = (startIndex + 10).clamp(0, data.transactions.length);
          final pageTransactions = data.transactions.sublist(startIndex, endIndex);
          final totalPages = (data.transactions.length / 10).ceil();

          return Column(
            children: [
              Container(
                color: Colors.blue[50],
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${data.user.phone}, ${data.user.email}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _summaryBox('Total Paid', '- ₹${data.totalPaid}', data.totalPaidCount, Colors.red)),
                        Expanded(child: _summaryBox('Total Received', '+ ₹${data.totalReceived}', data.totalReceivedCount, Colors.green))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Statement: ${dateFmt.format(selectedDateRange!.start)} - ${dateFmt.format(selectedDateRange!.end)}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: const [
                          SizedBox(width: 80, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Your Account', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: pageTransactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final txn = pageTransactions[index];
                          final date = DateTime.parse(txn.dateTime);
                          return Container(
                            color: index % 2 == 0 ? Colors.white : Colors.grey[100],
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(DateFormat('h:mm a').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(txn.details, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('Ref No: ${txn.upiRef}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('# ${txn.tag}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(txn.accountName, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${txn.isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(2)}',
                                          style: TextStyle(color: txn.isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                      Text('Bal: ₹${txn.availableBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                              icon: const Icon(Icons.arrow_back_ios),
                            ),
                            Text('Page ${currentPage + 1} of $totalPages'),
                            IconButton(
                              onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _summaryBox(String title, String amount, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          Text('$count Payments', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class PassbookData {
  final User user;
  final List<Transaction> transactions;
  final double totalPaid;
  final double totalReceived;
  final int totalPaidCount;
  final int totalReceivedCount;

  PassbookData({
    required this.user,
    required this.transactions,
    required this.totalPaid,
    required this.totalReceived,
    required this.totalPaidCount,
    required this.totalReceivedCount,
  });

  factory PassbookData.fromJson(Map<String, dynamic> json) {
    return PassbookData(
      user: User.fromJson(json['user']),
      transactions: (json['transactions'] as List)
          .map((e) => Transaction.fromJson(e))
          .toList(),
      totalPaid: json['totalPaid'].toDouble(),
      totalReceived: json['totalReceived'].toDouble(),
      totalPaidCount: json['totalPaidCount'],
      totalReceivedCount: json['totalReceivedCount'],
    );
  }
}

class User {
  final String name;
  final String phone;
  final String email;

  User({required this.name, required this.phone, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}

class Transaction {
  final String dateTime;
  final String details;
  final String upiRef;
  final String tag;
  final String accountName;
  final double amount;
  final bool isCredit;
  final double availableBalance;

  Transaction({
    required this.dateTime,
    required this.details,
    required this.upiRef,
    required this.tag,
    required this.accountName,
    required this.amount,
    required this.isCredit,
    required this.availableBalance,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      dateTime: json['dateTime'],
      details: json['details'],
      upiRef: json['upiRef'],
      tag: json['tag'],
      accountName: json['accountName'],
      amount: json['amount'].toDouble(),
      isCredit: json['isCredit'],
      availableBalance: json['availableBalance'].toDouble(),
    );
  }
}

Future<PassbookData> fetchPassBook(String phone, DateTime start, DateTime end) async {
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final startStr = dateFormatter.format(start);
  final endStr = dateFormatter.format(end);

  final response = await http.get(
    Uri.parse('${ApiHandler.baseUri1}/PayIn/GetPassbook?phone=$phone&startDate=$startStr&endDate=$endStr'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return PassbookData.fromJson(data);
  } else {
    throw Exception('Failed to load passbook');
  }
}
