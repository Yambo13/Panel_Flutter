import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
//import 'package:flutter/foundation.dart'; //Para usar kisWeb
//import 'package:webview_flutter_web/webview_flutter_web.dart';
//import 'package:webview_windows/webview_windows.dart'; // Motor Windows

class WebChartScreen extends StatefulWidget {
  final String url;

  const WebChartScreen({super.key, required this.url});

  @override
  State<WebChartScreen> createState() => _WebChartScreenState();
}

class _WebChartScreenState extends State<WebChartScreen> {
  // Controladores para cada plataforma
  //final _mobileController = WebViewController(); 
  //final _windowsController = WebviewController();
   late final WebViewController _controller;
  bool _isLoading = true; // Para saber si Windows cargó

  @override
  void initState() {
    super.initState();

    // Inicializamos el controlador (Funciona en Web y Móvil)
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Error web: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gráfica Qartia"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // En Web, esto renderiza un <iframe> HTML nativo
          WebViewWidget(controller: _controller),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}