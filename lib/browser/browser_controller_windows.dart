import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';

import 'url_utils.dart';
import 'web_clipboard_bridge.dart';

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
          errorMessage = 'Không tải được trang: $status';
          notifyListeners();
        }),
      );

      await webviewController.loadUrl(urlTextController.text);
      isInitialized = true;
      errorMessage = null;
      notifyListeners();
    } on PlatformException catch (e) {
      errorMessage = 'Lỗi khởi tạo WebView: ${e.message ?? e.code}';
      notifyListeners();
    }
  }

  Future<void> openInputUrl() async {
    final url = UrlUtils.normalizeUrl(urlTextController.text);
    urlTextController.text = url;
    errorMessage = null;
    notifyListeners();
    await webviewController.loadUrl(url);
  }

  Future<void> goHome() async {
    urlTextController.text = UrlUtils.defaultUrl;
    await openInputUrl();
  }

  Future<void> goBack() async {
    if (!canGoBack) {
      return;
    }
    await webviewController.goBack();
  }

  Future<void> goForward() async {
    if (!canGoForward) {
      return;
    }
    await webviewController.goForward();
  }

  Future<void> reload() => webviewController.reload();

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
