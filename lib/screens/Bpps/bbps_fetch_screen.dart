import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'bbps_payment_screen.dart';
import 'bbps_category_config.dart';

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

  bool isLoading = false;
  bool isBillFetched = false;

  Map<String, String> parsedBill = {};
  Map<String, String> additionalInfo = {};

  /// 🔥 STORE RAW XMLs (IMPORTANT FOR PAYMENT)
  String rawXml = "";
  String rawAdditionalInfoXml = "";
  String rawBillInfoXml = "";
  String enquiryReferenceId = "";
  String rawBillerResponseXml = "";

  final TextEditingController amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final config = bbpsConfig[widget.category];
    for (var f in config!.fields) {
      controllers[f["key"]!] = TextEditingController();
    }
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  /// 🔥 XML PARSER
  void parseXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);

      final responseCode =
          document.findAllElements('responseCode').isNotEmpty
              ? document.findAllElements('responseCode').first.text
              : "";

      if (responseCode != "000") {
        final errorMessage =
            document.findAllElements('errorMessage').isNotEmpty
                ? document.findAllElements('errorMessage').first.text
                : "Bill Fetch Failed";

        showToast(errorMessage);
        parsedBill.clear();
        additionalInfo.clear();
        isBillFetched = false;
        return;
      }

      /// BILL DATA
      parsedBill.clear();
      final billerResponse = document.findAllElements('billerResponse');

      if (billerResponse.isNotEmpty) {
        for (var node
            in billerResponse.first.children.whereType<XmlElement>()) {
          parsedBill[node.name.local] = node.text;
        }
      }

      /// ADDITIONAL INFO
      additionalInfo.clear();
      final additional = document.findAllElements('additionalInfo');

      if (additional.isNotEmpty) {
        for (var info in additional.first.findAllElements('info')) {
          final name = info.getElement('infoName')?.text ?? "Info";
          final value = info.getElement('infoValue')?.text ?? "";
          additionalInfo[name] = value;
        }
      }
    } catch (e) {
      showToast("XML Parse Error");
    }
  }

  Future<void> fetchBill() async {
    setState(() => isLoading = true);

    try {
      final inputs = controllers.entries.map((e) {
        return {
          "paramName": e.key,
          "paramValue": e.value.text,
        };
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

  void goToPayment() {
    final inputs = controllers.entries.map((e) {
      return {
        "paramName": e.key,
        "paramValue": e.value.text,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BBPSPaymentScreen(
          biller: widget.biller,
          parsedBill: parsedBill,
          rawXml: rawXml, // 🔥 PASS FULL XML
          additionalInfo: rawAdditionalInfoXml,
          billFetchResponse: rawBillInfoXml,
          billerResponse: rawBillerResponseXml,
          userPhone: widget.userPhone,
          category: widget.category,
          device: "mobile",
          inputs: inputs,
          amount: double.tryParse(amountCtrl.text) ?? 0,
          enquiryReferenceId: enquiryReferenceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = bbpsConfig[widget.category]!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.biller['billerName'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              if (!isBillFetched)
                ...config.fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[f["key"]],
                        decoration: InputDecoration(
                          labelText: f["label"],
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )),

              if (!isBillFetched)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : fetchBill,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Fetch Bill"),
                  ),
                ),

              if (isBillFetched) ...[
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      ...parsedBill.entries
                          .map((e) => rowItem(e.key, e.value)),
                      const Divider(),
                      ...additionalInfo.entries
                          .map((e) => rowItem(e.key, e.value)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter Amount",
                    prefixText: "₹ ",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: goToPayment,
                    child: const Text("Pay Now"),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}