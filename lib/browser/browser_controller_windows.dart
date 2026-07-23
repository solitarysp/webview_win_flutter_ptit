import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';

import 'url_utils.dart';
import 'web_clipboard_bridge.dart';
import 'web_error_text.dart';

class BrowserControllerWindows extends ChangeNotifier {
  BrowserControllerWindows({
    WebviewController? webviewController,
    TextEditingController? urlTextController,
  }) : webviewController = webviewController ?? WebviewController(),
       urlTextController =
           urlTextController ??
           TextEditingController(text: UrlUtils.defaultUrl);

  final WebviewController webviewController;
  final TextEditingController urlTextController;

  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  bool isInitialized = false;
  bool isLoading = false;
  bool canGoBack = false;
  bool canGoForward = false;
  String? errorMessage;

  Future<void> initialize() async {
    try {
      final version = await WebviewController.getWebViewVersion();
      if (version == null) {
        errorMessage =
            'Thiếu Microsoft Edge WebView2 Runtime. Hãy cài trước khi dùng app.';
        notifyListeners();
        return;
      }

      await webviewController.initialize();
      await webviewController.setUserAgent(
        UrlUtils.chromeUserAgentForWindows(),
      );

      _subscriptions.add(
        webviewController.url.listen((url) {
          urlTextController.text = url;
        }),
      );
      _subscriptions.add(
        webviewController.loadingState.listen((state) {
          isLoading = state == LoadingState.loading;
          if (isLoading) {
            errorMessage = null;
          }
          notifyListeners();
        }),
      );
      _subscriptions.add(
        webviewController.historyChanged.listen((history) {
          canGoBack = history.canGoBack;
          canGoForward = history.canGoForward;
          notifyListeners();
        }),
      );
      _subscriptions.add(
        webviewController.onLoadError.listen((status) {
          isLoading = false;
          errorMessage = buildWindowsWebLoadErrorMessage('$status');
          notifyListeners();
        }),
      );

      isLoading = true;
      await webviewController.loadUrl(urlTextController.text);
      isInitialized = true;
      errorMessage = null;
      notifyListeners();
    } on PlatformException catch (e) {
      isLoading = false;
      errorMessage = 'Lỗi khởi tạo WebView: ${e.message ?? e.code}';
      notifyListeners();
    }
  }

  Future<void> openInputUrl() async {
    final url = UrlUtils.normalizeUrl(urlTextController.text);
    urlTextController.text = url;
    await _navigate(() => webviewController.loadUrl(url));
  }

  Future<void> goHome() async {
    urlTextController.text = UrlUtils.defaultUrl;
    await openInputUrl();
  }

  Future<void> goBack() async {
    if (!canGoBack) {
      return;
    }
    await _navigate(webviewController.goBack);
  }

  Future<void> goForward() async {
    if (!canGoForward) {
      return;
    }
    await _navigate(webviewController.goForward);
  }

  Future<void> reload() => _navigate(webviewController.reload);

  Future<String> copySelectionToClipboard() {
    return WebClipboardBridge.copySelectedText(
      runScript: webviewController.executeScript,
    );
  }

  Future<String> pasteTextFromClipboard() {
    return WebClipboardBridge.pasteTextFromClipboard(
      runScript: webviewController.executeScript,
    );
  }

  Future<String> pasteImageFromClipboard() {
    return WebClipboardBridge.pasteImageFromClipboard(
      runScript: webviewController.executeScript,
    );
  }

  Future<void> _navigate(Future<void> Function() action) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await action();
    } on PlatformException catch (e) {
      isLoading = false;
      errorMessage = 'Không tải được trang: ${e.message ?? e.code}';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    webviewController.dispose();
    urlTextController.dispose();
    super.dispose();
  }
}
