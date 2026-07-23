import 'package:flutter_test/flutter_test.dart';
import 'package:webview_win_flutter/browser/web_clipboard_bridge.dart';

void main() {
  group('WebClipboardBridge.normalizeScriptResult', () {
    test('decodes quoted json string from script engines', () {
      expect(WebClipboardBridge.normalizeScriptResult('"OK"'), 'OK');
    });

    test('returns raw string when not json', () {
      expect(
        WebClipboardBridge.normalizeScriptResult('NO_ACTIVE_ELEMENT'),
        'NO_ACTIVE_ELEMENT',
      );
    });

    test('handles null as empty string', () {
      expect(WebClipboardBridge.normalizeScriptResult(null), '');
    });
  });

  group('WebClipboardBridge script builders', () {
    test('paste text script contains escaped payload', () {
      final script = WebClipboardBridge.buildPasteTextScript('hello "world"');
      expect(script, contains('hello \\"world\\"'));
      expect(script, contains("return 'OK'"));
    });

    test('paste image script contains data url payload', () {
      final script = WebClipboardBridge.buildPasteImageScript(
        'data:image/png;base64,AAA',
      );
      expect(script, contains('data:image/png;base64,AAA'));
      expect(script, contains('ClipboardEvent'));
    });
  });
}
