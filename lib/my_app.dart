// material.dart package
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'web_view_controller.dart';
import 'web_view_screen.dart'; // Import your WebViewScreen

class MyApp extends StatefulWidget {
  final String flavor;

  const MyApp({Key? key, required this.flavor}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final WebViewManager _webViewManager = WebViewManager();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        WebView.platform = SurfaceAndroidWebView();
      }
      // Handle iOS separately if there's a specific configuration needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Flavors Example',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.flavor),
        ),
        body: WebViewScreen(
          manager: _webViewManager,
          url: '', // Provide the URL you want to load
        ),
      ),
    );
  }
}
