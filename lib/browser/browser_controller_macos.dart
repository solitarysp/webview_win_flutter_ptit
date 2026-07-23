import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'url_utils.dart';
import 'web_clipboard_bridge.dart';

class BrowserControllerMacos extends ChangeNotifier {
  BrowserControllerMacos({TextEditingController? initialUrlTextController})
    : urlTextController =
          initialUrlTextController ??
          TextEditingController(text: UrlUtils.defaultUrl),
      webviewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted) {
    webviewController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          isLoading = true;
          errorMessage = null;
          urlTextController.text = url;
          _syncHistoryState();
          notifyListeners();
        },
        onPageFinished: (url) {
          isLoading = false;
          urlTextController.text = url;
          _syncHistoryState();
          notifyListeners();
        },
        onWebResourceError: (error) {
          isLoading = false;
          errorMessage = 'Không tải được trang: ${error.description}';
          notifyListeners();
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url != null && url.isNotEmpty) {
            urlTextController.text = url;
            _syncHistoryState();
            notifyListeners();
          }
        },
      ),
    );
  }

  final TextEditingController urlTextController;
  final WebViewController webviewController;

  bool isInitialized = false;
  bool isLoading = false;
  bool canGoBack = false;
  bool canGoForward = false;
  bool _isDisposed = false;
  String? errorMessage;

  Future<void> initialize() async {
    await webviewController.setUserAgent(UrlUtils.chromeUserAgentForMacos());
    await openInputUrl();
    isInitialized = true;
    notifyListeners();
  }

  Future<void> openInputUrl() async {
    final url = UrlUtils.normalizeUrl(urlTextController.text);
    urlTextController.text = url;
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    await webviewController.loadRequest(Uri.parse(url));
    await _updateHistoryState();
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
    await _updateHistoryState();
  }

  Future<void> goForward() async {
    if (!canGoForward) {
      return;
    }
    await webviewController.goForward();
    await _updateHistoryState();
  }

  Future<void> reload() => webviewController.reload();

  Future<String> copySelectionToClipboard() {
    return WebClipboardBridge.copySelectedText(
      runScript: webviewController.runJavaScriptReturningResult,
    );
  }

  Future<String> pasteTextFromClipboard() {
    return WebClipboardBridge.pasteTextFromClipboard(
      runScript: webviewController.runJavaScriptReturningResult,
    );
  }

  Future<String> pasteImageFromClipboard() {
    return WebClipboardBridge.pasteImageFromClipboard(
      runScript: webviewController.runJavaScriptReturningResult,
    );
  }

  void _syncHistoryState() {
    _updateHistoryState();
  }

  Future<void> _updateHistoryState() async {
    if (_isDisposed) {
      return;
    }
    final back = await webviewController.canGoBack();
    final forward = await webviewController.canGoForward();
    if (_isDisposed) {
      return;
    }
    canGoBack = back;
    canGoForward = forward;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    urlTextController.dispose();
    super.dispose();
  }
}
