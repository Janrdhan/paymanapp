import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';

class BillerInputParam {
  final String paramName;
  final String dataType;
  final bool isOptional;
  final int minLength;
  final int maxLength;
  final String regEx;
  final bool visibility;

  BillerInputParam({
    required this.paramName,
    required this.dataType,
    required this.isOptional,
    required this.minLength,
    required this.maxLength,
    required this.regEx,
    required this.visibility,
  });
}

class BBPSFetchScreen extends StatefulWidget {
  final dynamic biller;
  final String userPhone;
  final String category;

  const BBPSFetchScreen({
    super.key,
    required this.biller,
    required this.userPhone,
    required this.category,
  });

  @override
  State<BBPSFetchScreen> createState() => _BBPSFetchScreenState();
}

class _BBPSFetchScreenState extends State<BBPSFetchScreen> {
  Map<String, TextEditingController> controllers = {};
  List<BillerInputParam> billerInputParams = [];

  bool isLoadingConfig = true;
  bool isLoading = false;
  bool isBillFetched = false;
  String? configError;

  Map<String, String> parsedBill = {};
  Map<String, String> additionalInfo = {};

  String rawXml = "";
  String rawAdditionalInfoXml = "";
  String rawBillInfoXml = "";
  String enquiryReferenceId = "";
  String rawBillerResponseXml = "";

  final TextEditingController amountCtrl = TextEditingController();

  bool _isProcessingPayment = false;

  double _walletBalance = 0.0;
  double _payoutBankAmount = 0.0;
  int _payOutMaxAmount = 2000000;
  int _payOutMinAmount = 100;
  int _minBalanceAvl = 100;

  @override
  void initState() {
    super.initState();
    loadBillerConfig();
    _fetchWalletBalance();
    _fetchPayoutConfiguration();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetBalance?userPhone=${widget.userPhone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _walletBalance = _toDouble(data['balance']));
      }
    } catch (e) {
      print("Balance fetch error: $e");
    }
  }

  Future<void> _fetchPayoutConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetPayoutConfigurationDetails?userPhone=${widget.userPhone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _payoutBankAmount = _toDouble(data['billAvenueAmount']);
          _payOutMaxAmount = _toInt(data['billAvenueOutMaxAmount']) ?? 3000000;
          _payOutMinAmount = _toInt(data['payOutMinAmount']) ?? 100;
          _minBalanceAvl = _toInt(data['minBalanceAvl']) ?? 100;
        });
      } else {
        _setPayoutDefaults();
      }
    } catch (e) {
      print("Payout details error: $e");
      _setPayoutDefaults();
    }
  }

  void _setPayoutDefaults() {
    setState(() {
      _payoutBankAmount = 50000;
      _payOutMaxAmount = 2000000;
      _payOutMinAmount = 100;
      _minBalanceAvl = 100;
    });
  }

  List<BillerInputParam> _parseInputParams(XmlDocument document) {
    final params = <BillerInputParam>[];
    final billerInputParamsElement = document.findAllElements('billerInputParams').firstOrNull;
    if (billerInputParamsElement == null) return params;
    final paramNodes = billerInputParamsElement.findAllElements('paramInfo');
    for (var node in paramNodes) {
      String getText(String tag, {String defaultValue = ''}) {
        final elements = node.findElements(tag);
        return elements.isNotEmpty ? elements.first.text : defaultValue;
      }
      final paramName = getText('paramName');
      if (paramName.isEmpty) continue;
      final dataType = getText('dataType', defaultValue: 'ALPHANUMERIC');
      final isOptional = getText('isOptional', defaultValue: 'false').toLowerCase() == 'true';
      final minLength = int.tryParse(getText('minLength')) ?? 0;
      final maxLength = int.tryParse(getText('maxLength')) ?? 0;
      final regEx = getText('regEx');
      final visibility = getText('visibility', defaultValue: 'true').toLowerCase() == 'true';
      params.add(BillerInputParam(
        paramName: paramName,
        dataType: dataType,
        isOptional: isOptional,
        minLength: minLength,
        maxLength: maxLength,
        regEx: regEx,
        visibility: visibility,
      ));
    }
    return params;
  }

  Future<void> loadBillerConfig() async {
    setState(() {
      isLoadingConfig = true;
      configError = null;
      billerInputParams.clear();
      controllers.clear();
    });
    try {
      print("Fetching config for billerId: ${widget.biller['billerId']}, category: ${widget.category}");
      final uri = Uri.parse(
        '${ApiHandler.baseUri}/BillPayments/CheckBillerCategory',
      ).replace(queryParameters: {
        "BillerName": widget.category,
        "UserPhone": widget.userPhone,
        "BillerId": widget.biller['billerId'].toString(),
      });
      final res = await http.get(uri, headers: {"Content-Type": "application/json"});
      final data = jsonDecode(res.body);
      bool isAvailable = data['isAvailable'] ?? false;
      String rawCategoryKey = data['categoryKey'] ?? '';

      if (!isAvailable) {
        setState(() => configError = "Biller is not available");
        return;
      }

      if (!rawCategoryKey.trim().startsWith('<?xml')) {
        setState(() => configError = "Invalid response format from server");
        return;
      }

      final document = XmlDocument.parse(rawCategoryKey);
      final params = _parseInputParams(document);

      if (params.isEmpty) {
        setState(() => configError = "No input parameters defined for this biller");
        return;
      }

      for (var param in params.where((p) => !p.isOptional)) {
        controllers[param.paramName] = TextEditingController();
        controllers[param.paramName]!.addListener(_onFormChanged);
      }

      setState(() {
        billerInputParams = params;
      });
    } catch (e, stack) {
      print("XML parsing error: $e");
      print(stack);
      setState(() => configError = "Error loading configuration: ${e.toString()}");
    } finally {
      setState(() => isLoadingConfig = false);
    }
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool _isFormValid() {
    for (var param in billerInputParams.where((p) => !p.isOptional)) {
      final controller = controllers[param.paramName];
      if (controller == null || controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  bool _isBillAmountKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'billamount' ||
        lower == 'amount' ||
        lower == 'dueamount' ||
        lower == 'outstandingamount' ||
        lower == 'totalamount' ||
        lower == 'payableamount';
  }

  String _convertAmount(String raw) {
    // Extract only numeric part (including decimal) – removes any trailing letters
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return raw;
    final numStr = match.group(1)!;
    final numValue = double.tryParse(numStr);
    if (numValue == null) return raw;
    return (numValue / 100).toStringAsFixed(2);
  }

  void parseXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final responseCode = document.findAllElements('responseCode').isNotEmpty
          ? document.findAllElements('responseCode').first.text
          : "";
      if (responseCode != "000") {
        final errorMessage = document.findAllElements('errorMessage').isNotEmpty
            ? document.findAllElements('errorMessage').first.text
            : "Bill Fetch Failed";
        showToast(errorMessage);
        parsedBill.clear();
        additionalInfo.clear();
        isBillFetched = false;
        return;
      }
      parsedBill.clear();
      final billerResponse = document.findAllElements('billerResponse');
      if (billerResponse.isNotEmpty) {
        for (var node in billerResponse.first.children.whereType<XmlElement>()) {
          final key = node.name.local;
          var value = node.text.trim();
          if (_isBillAmountKey(key) && value.isNotEmpty) {
            value = _convertAmount(value);
          }
          parsedBill[key] = value;
        }
      }
      additionalInfo.clear();
      final additional = document.findAllElements('additionalInfo');
      if (additional.isNotEmpty) {
        for (var info in additional.first.findAllElements('info')) {
          final name = info.getElement('infoName')?.text ?? "Info";
          final rawValue = info.getElement('infoValue')?.text ?? "";
          var value = rawValue.trim();
          if (_isBillAmountKey(name) && value.isNotEmpty) {
            value = _convertAmount(value);
          }
          additionalInfo[name] = value;
        }
      }
    } catch (e) {
      showToast("XML Parse Error");
    }
  }

  Future<void> fetchBill() async {
    if (!_isFormValid()) {
      showToast("Please fill all required fields");
      return;
    }

    setState(() => isLoading = true);
    try {
      final inputs = controllers.entries.map((e) {
        return {"paramName": e.key, "paramValue": e.value.text};
      }).toList();
      final res = await http.post(
        Uri.parse('${ApiHandler.baseUri}/BillPayments/BBPSFetchBill'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "billerId": widget.biller['billerId'],
          "userPhone": widget.userPhone,
          "category": widget.category,
          "inputs": inputs,
        }),
      );
      if (res.statusCode != 200) {
        showToast("Server Error");
        return;
      }
      final data = jsonDecode(res.body);
      if (data["status"] != true) {
        showToast(data["message"] ?? "Failed to fetch bill");
        return;
      }
      rawXml = data["billerResponse"] ?? "";
      rawAdditionalInfoXml = data["additionalInfo"] ?? "";
      rawBillInfoXml = data["billFetchResponse"] ?? "";
      rawBillerResponseXml = data["billerResponse1"] ?? "";
      enquiryReferenceId = data["enquiryReferenceId"] ?? "";
      if (rawXml.isEmpty) {
        showToast("Invalid response");
        return;
      }
      parseXml(rawXml);
      if (parsedBill.isEmpty) return;
      setState(() {
        isBillFetched = true;
        amountCtrl.text = parsedBill['billAmount'] ?? "0";
      });
    } catch (e) {
      showToast("Network Error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _validateAmountWithWallet(double amount) async {
    await Future.wait([_fetchWalletBalance(), _fetchPayoutConfiguration()]);
    if (amount < _payOutMinAmount || amount > _payOutMaxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Amount must be between ₹$_payOutMinAmount and ₹$_payOutMaxAmount")));
      return false;
    }
    if (_walletBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient wallet balance")));
      return false;
    }
    if (_payoutBankAmount < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service not available")));
      return false;
    }
    final remainingAfterPayment = _walletBalance - amount;
    if (remainingAfterPayment < _minBalanceAvl) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient wallet balance. You must maintain at least ₹$_minBalanceAvl in your wallet.")));
      return false;
    }
    return true;
  }

  Future<String?> _showPinDialog() async {
    final pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "PIN", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN cannot be empty")));
                return;
              }
              Navigator.pop(context, pin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<bool> _validatePin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiHandler.baseUri}/PayOut/ValidatePin'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Phone": widget.userPhone, "Pin": pin}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showProcessingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text("Processing payment, please wait..."),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executePayment() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiHandler.baseUri}/BillPayments/BBPSPayBill'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "billerId": widget.biller['billerId'],
          "userPhone": widget.userPhone,
          "amount": double.tryParse(amountCtrl.text) ?? 0,
          "category": widget.category,
          "device": "mobile",
          "enquiryReferenceId": enquiryReferenceId,
          "billFetchResponse": rawBillInfoXml,
          "billerResponse": rawBillerResponseXml,
          "additionalInfo": rawAdditionalInfoXml,
          "inputs": controllers.entries.map((e) => {"paramName": e.key, "paramValue": e.value.text}).toList(),
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode != 200) {
        showToast("Server Error");
        return;
      }
      if (data["success"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              phone: data["userPhone"] ?? "",
              amount: data["amount"] ?? "",
              userName: data["userName"] ?? "",
              customerType: "BBPS",
            ),
          ),
        );
      } else {
        showToast(data["message"] ?? "Payment Failed");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentFailureScreen(phone: data["userPhone"] ?? "")),
        );
      }
    } catch (e) {
      showToast("Network error during payment");
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _startPayment() async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) {
      showToast("Invalid amount");
      setState(() => _isProcessingPayment = false);
      return;
    }
    if (!await _validateAmountWithWallet(amount)) {
      setState(() => _isProcessingPayment = false);
      return;
    }
    final pin = await _showPinDialog();
    if (pin == null || pin.length < 4) {
      if (pin != null) showToast("PIN must be at least 4 digits");
      setState(() => _isProcessingPayment = false);
      return;
    }
    if (!await _validatePin(pin)) {
      showToast("Invalid PIN");
      setState(() => _isProcessingPayment = false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: "Pay ₹"),
              TextSpan(text: amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: " for "),
              TextSpan(text: widget.biller['billerName'] ?? "this bill", style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: "?"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)), child: const Text("Confirm")),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _isProcessingPayment = false);
      return;
    }
    await _showProcessingDialog();
    await _executePayment();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessingPayment) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment is processing, please wait…")));
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: Text(widget.biller['billerName'] ?? "Pay Bill", style: const TextStyle(fontWeight: FontWeight.w600)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoadingConfig) return const Center(child: CircularProgressIndicator());
    if (configError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(configError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: loadBillerConfig, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (billerInputParams.isEmpty) return const Center(child: Text("No input fields available for this biller"));

    final requiredFields = billerInputParams.where((p) => !p.isOptional).toList();
    if (requiredFields.isEmpty) return const Center(child: Text("No required fields for this biller"));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.receipt, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.biller['billerName'] ?? "Bill Payment", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Enter details to fetch your bill", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!isBillFetched) ...[
            ...requiredFields.map((param) {
              final controller = controllers[param.paramName];
              if (controller == null) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildDynamicInputField(param: param, controller: controller));
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isFormValid() && !isLoading) ? fetchBill : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Fetch Bill", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          if (isBillFetched) ...[
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text("Bill Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                  const Divider(height: 0, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [...parsedBill.entries.map((e) => _buildInfoRow(e.key, e.value)), if (additionalInfo.isNotEmpty) ...[const SizedBox(height: 12), const Divider(), const SizedBox(height: 8), ...additionalInfo.entries.map((e) => _buildInfoRow(e.key, e.value))]]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee, color: Color(0xFF2563EB)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isProcessingPayment || !isBillFetched) ? null : _startPayment,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: _isProcessingPayment
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicInputField({required BillerInputParam param, required TextEditingController controller}) {
    String? validator(String? value) {
      if (value == null || value.isEmpty) return param.isOptional ? null : "This field is required";
      if (value.length < param.minLength) return "Minimum ${param.minLength} characters required";
      if (value.length > param.maxLength) return "Maximum ${param.maxLength} characters allowed";
      if (param.regEx.isNotEmpty && !RegExp(param.regEx).hasMatch(value)) return "Invalid format";
      if (param.dataType == "NUMERIC" && !RegExp(r'^\d+$').hasMatch(value)) return "Only numbers allowed";
      return null;
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: param.paramName,
          prefixIcon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 1, child: Text(_formatLabel(label), style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    String result = key.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]|^[a-z]'), (m) => ' ${m.group(0)}').trim();
    if (result.isNotEmpty) result = result[0].toUpperCase() + result.substring(1);
    return result;
  }
}