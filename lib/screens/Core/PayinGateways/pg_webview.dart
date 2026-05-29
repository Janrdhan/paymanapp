import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/PayinGateways/payment_failure.dart';
import 'package:paymanapp/screens/Core/PayinGateways/payment_success.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PGWebView extends StatefulWidget {
  final String paymentUrl;
  final String phone;
  final String amount;

  const PGWebView({
    required this.paymentUrl,
    required this.phone,
    required this.amount,
    super.key,
  });

  @override
  State<PGWebView> createState() => _PGWebViewState();
}

class _PGWebViewState extends State<PGWebView> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => isLoading = false);
          },
          onNavigationRequest: (request) async {
            final url = request.url;

            // ✅ Detect backend redirect URL
            if (url.contains("/PayMan/PayStatus")) {
              final uri = Uri.parse(url);

              final isSuccess =
                  uri.queryParameters["IsSuccess"]?.toLowerCase();
              final amount =
                  uri.queryParameters["Amount"] ?? widget.amount;

              // 🔥 SHOW ALERT BEFORE NAVIGATION
              // await showDialog(
              //   context: context,
              //   builder: (_) => AlertDialog(
              //     title: const Text("Payment Redirect URL"),
              //     content: SingleChildScrollView(
              //       child: Text(url),
              //     ),
              //     actions: [
              //       TextButton(
              //         onPressed: () => Navigator.pop(context),
              //         child: const Text("OK"),
              //       ),
              //     ],
              //   ),
              // );

              // 🔥 AFTER USER PRESSES OK -> NAVIGATE
              if (isSuccess == "true") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentSuccess(
                      phone: widget.phone,
                      amount: amount,
                      userName: "PAYMAN",
                      customerType: "Retailer",
                    ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PaymentFailure(phone: widget.phone),
                  ),
                );
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back during payment
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Complete Payment"),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}