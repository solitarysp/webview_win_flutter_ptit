import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

typedef RunWebScript = Future<dynamic> Function(String script);

class WebClipboardBridge {
  WebClipboardBridge._();

  static Future<String> copySelectedText({
    required RunWebScript runScript,
  }) async {
    final raw = await runScript(_copySelectionScript);
    final selectedText = normalizeScriptResult(raw);
    if (selectedText.trim().isEmpty) {
      return 'Không có text được chọn để copy.';
    }

    await Clipboard.setData(ClipboardData(text: selectedText));
    return 'Đã copy text đã chọn.';
  }

  static Future<String> pasteTextFromClipboard({
    required RunWebScript runScript,
  }) async {
    final textData = await Clipboard.getData('text/plain');
    final text = textData?.text;
    if (text == null || text.isEmpty) {
      return 'Clipboard chưa có text để paste.';
    }

    final raw = await runScript(buildPasteTextScript(text));
    final result = normalizeScriptResult(raw);
    return switch (result) {
      'OK' => 'Đã paste text vào trang web.',
      'NO_ACTIVE_ELEMENT' => 'Hãy click vào ô nhập trên web rồi thử lại.',
      _ => 'Trang hiện tại không hỗ trợ paste text tự động.',
    };
  }

  static Future<String> pasteImageFromClipboard({
    required RunWebScript runScript,
  }) async {
    final imageBytes = await _readClipboardImageBytes();
    if (imageBytes == null || imageBytes.isEmpty) {
      return 'Clipboard chưa có ảnh PNG/JPEG để paste.';
    }

    final dataUrl = 'data:image/png;base64,${base64Encode(imageBytes)}';
    final raw = await runScript(buildPasteImageScript(dataUrl));
    final result = normalizeScriptResult(raw);

    return switch (result) {
      'OK' => 'Đã gửi ảnh paste vào web app (nếu web hỗ trợ).',
      'NO_ACTIVE_ELEMENT' =>
        'Hãy click vào vùng upload/chat trên web rồi paste lại.',
      _ => 'Trang hiện tại không chấp nhận paste ảnh bằng script.',
    };
  }

  static String normalizeScriptResult(dynamic raw) {
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      final value = raw.trim();
      try {
        final decoded = jsonDecode(value);
        if (decoded is String) {
          return decoded;
        }
        return decoded?.toString() ?? '';
      } catch (_) {
        return value;
      }
    }
    return raw.toString();
  }

  static String buildPasteTextScript(String text) {
    final escaped = jsonEncode(text);
    return '''
(() => {
  const text = $escaped;
  const active = document.activeElement;
  if (!active) return 'NO_ACTIVE_ELEMENT';

  const isInput = active.tagName === 'INPUT' || active.tagName === 'TEXTAREA';
  if (isInput) {
    const start = active.selectionStart ?? active.value.length;
    const end = active.selectionEnd ?? start;
    active.value = active.value.slice(0, start) + text + active.value.slice(end);
    active.dispatchEvent(new Event('input', { bubbles: true }));
    active.dispatchEvent(new Event('change', { bubbles: true }));
    active.selectionStart = active.selectionEnd = start + text.length;
    return 'OK';
  }

  if (active.isContentEditable) {
    document.execCommand('insertText', false, text);
    return 'OK';
  }

  return 'UNSUPPORTED';
})();
''';
  }

  static String buildPasteImageScript(String dataUrl) {
    final escaped = jsonEncode(dataUrl);
    return '''
(async () => {
  const dataUrl = $escaped;
  const active = document.activeElement;
  if (!active) return 'NO_ACTIVE_ELEMENT';

  try {
    const response = await fetch(dataUrl);
    const blob = await response.blob();
    const file = new File([blob], 'clipboard.png', { type: 'image/png' });
    const transfer = new DataTransfer();
    transfer.items.add(file);
    const event = new ClipboardEvent('paste', {
      clipboardData: transfer,
      bubbles: true,
      cancelable: true,
    });

    if (active.isContentEditable) {
      const image = document.createElement('img');
      image.src = dataUrl;
      active.appendChild(image);
    }

    active.dispatchEvent(event);
    return 'OK';
  } catch (_) {
    return 'UNSUPPORTED';
  }
})();
''';
  }

  static const String _copySelectionScript = '''
(() => {
  const active = document.activeElement;
  const isInput = active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA');
  if (isInput && active.selectionStart !== null && active.selectionEnd !== null) {
    return active.value.substring(active.selectionStart, active.selectionEnd);
  }

  const selection = window.getSelection();
  return selection ? selection.toString() : '';
})();
''';

  static Future<Uint8List?> _readClipboardImageBytes() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return null;
    }

    final reader = await clipboard.read();
    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(Formats.png, (file) async {
      try {
        completer.complete(await file.readAll());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }, onError: (error) => completer.completeError(error));

    if (progress == null) {
      completer.complete(null);
    }

    return completer.future;
  }
}
