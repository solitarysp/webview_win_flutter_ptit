import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'browser_controller_windows.dart';

class BrowserPageWindows extends StatefulWidget {
  const BrowserPageWindows({super.key});

  @override
  State<BrowserPageWindows> createState() => _BrowserPageWindowsState();
}

class _BrowserPageWindowsState extends State<BrowserPageWindows> {
  late final BrowserControllerWindows _controller;

  Future<void> _handleClipboardAction(Future<String> Function() action) async {
    final message = await action();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _controller = BrowserControllerWindows()..initialize();
    _controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 360,
                        child: TextField(
                          controller: _controller.urlTextController,
                          textInputAction: TextInputAction.go,
                          decoration: const InputDecoration(
                            hintText: 'Nhập URL, ví dụ: github.com',
                            prefixIcon: Icon(Icons.language_rounded),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _controller.openInputUrl(),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _controller.isInitialized
                            ? _controller.openInputUrl
                            : null,
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Mở'),
                      ),
                      IconButton(
                        onPressed: _controller.isInitialized
                            ? _controller.goHome
                            : null,
                        tooltip: 'Home (Google)',
                        icon: const Icon(Icons.home_rounded),
                      ),
                      IconButton(
                        onPressed:
                            _controller.isInitialized && _controller.canGoBack
                            ? _controller.goBack
                            : null,
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      IconButton(
                        onPressed:
                            _controller.isInitialized &&
                                _controller.canGoForward
                            ? _controller.goForward
                            : null,
                        tooltip: 'Forward',
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      IconButton(
                        onPressed: _controller.isInitialized
                            ? _controller.reload
                            : null,
                        tooltip: 'Reload',
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      IconButton(
                        onPressed: _controller.isInitialized
                            ? () => _handleClipboardAction(
                                _controller.copySelectionToClipboard,
                              )
                            : null,
                        tooltip: 'Copy text',
                        icon: const Icon(Icons.content_copy_rounded),
                      ),
                      IconButton(
                        onPressed: _controller.isInitialized
                            ? () => _handleClipboardAction(
                                _controller.pasteTextFromClipboard,
                              )
                            : null,
                        tooltip: 'Paste text',
                        icon: const Icon(Icons.content_paste_rounded),
                      ),
                      IconButton(
                        onPressed: _controller.isInitialized
                            ? () => _handleClipboardAction(
                                _controller.pasteImageFromClipboard,
                              )
                            : null,
                        tooltip: 'Paste image',
                        icon: const Icon(Icons.image_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_controller.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  child: _controller.isInitialized
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Webview(_controller.webviewController),
                            ),
                            if (_controller.isLoading)
                              const Align(
                                alignment: Alignment.topCenter,
                                child: LinearProgressIndicator(minHeight: 3),
                              ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
