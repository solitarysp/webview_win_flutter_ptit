import 'package:flutter_test/flutter_test.dart';
import 'package:webview_win_flutter/browser/url_utils.dart';

void main() {
  group('UrlUtils.normalizeUrl', () {
    test('returns default when input is empty', () {
      expect(UrlUtils.normalizeUrl('   '), 'https://www.google.com');
    });

    test('keeps valid URL with scheme', () {
      expect(
        UrlUtils.normalizeUrl('https://flutter.dev'),
        'https://flutter.dev',
      );
    });

    test('adds https when scheme missing', () {
      expect(UrlUtils.normalizeUrl('github.com'), 'https://github.com');
    });

    test('fallback default for invalid host', () {
      expect(UrlUtils.normalizeUrl('not a url'), 'https://www.google.com');
    });
  });

  group('UrlUtils chrome user agent', () {
    test('builds windows chrome user agent', () {
      final userAgent = UrlUtils.chromeUserAgentForWindows();
      expect(userAgent, contains('Windows NT 10.0; Win64; x64'));
      expect(userAgent, contains('Chrome/${UrlUtils.chromeVersion}'));
      expect(userAgent, endsWith('Safari/537.36'));
    });

    test('builds macos chrome user agent', () {
      final userAgent = UrlUtils.chromeUserAgentForMacos();
      expect(userAgent, contains('Macintosh; Intel Mac OS X 10_15_7'));
      expect(userAgent, contains('Chrome/${UrlUtils.chromeVersion}'));
      expect(userAgent, endsWith('Safari/537.36'));
    });
  });
}
