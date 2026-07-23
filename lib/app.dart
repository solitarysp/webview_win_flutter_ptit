import 'package:flutter/material.dart';

import 'browser/browser_page.dart';

class WebviewWinApp extends StatelessWidget {
  const WebviewWinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF3B82F6);
    return MaterialApp(
      title: 'WebView Browser',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BrowserPage(),
    );
  }
}
