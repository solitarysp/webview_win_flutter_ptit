import 'dart:io';

import 'package:flutter/material.dart';

import 'browser_page_macos.dart';
import 'browser_page_windows.dart';

class BrowserPage extends StatelessWidget {
  const BrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return const BrowserPageWindows();
    }
    if (Platform.isMacOS) {
      return const BrowserPageMacos();
    }

    return const Scaffold(
      body: Center(
        child: Text('Nền tảng chưa hỗ trợ. Dùng Windows hoặc macOS.'),
      ),
    );
  }
}
