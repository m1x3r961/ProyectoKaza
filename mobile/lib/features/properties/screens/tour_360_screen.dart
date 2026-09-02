import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../app/theme/kaza_theme.dart';

class Tour360Screen extends StatefulWidget {
  final String url;
  final String title;

  const Tour360Screen({
    super.key,
    required this.url,
    this.title = 'Tour 360° Virtual',
  });

  @override
  State<Tour360Screen> createState() => _Tour360ScreenState();
}

class _Tour360ScreenState extends State<Tour360Screen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: KazaTheme.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KazaTheme.accentGold),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, color: KazaTheme.accentGold, size: 14),
                SizedBox(width: 4),
                Text('PREMIUM', style: TextStyle(color: KazaTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: KazaTheme.accentGold),
            ),
        ],
      ),
    );
  }
}
