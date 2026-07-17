import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymobIframeScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymobIframeScreen({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<PaymobIframeScreen> createState() => _PaymobIframeScreenState();
}

class _PaymobIframeScreenState extends State<PaymobIframeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // Paymob callback / txn response URLs
            if (url.contains('success=true') ||
                url.contains('txn_response_code=APPROVED')) {
              if (mounted) Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (url.contains('success=false') ||
                url.contains('txn_response_code=DECLINED')) {
              if (mounted) Navigator.pop(context, false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الدفع الآمن'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false), // User cancelled
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
