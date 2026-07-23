class UrlUtils {
  UrlUtils._();

  static const String defaultUrl = 'https://www.google.com';
  static const String firefoxVersion = '141.0';

  static String chromeUserAgentForWindows() =>
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:$firefoxVersion) '
      'Gecko/20100101 Firefox/$firefoxVersion';

  static String chromeUserAgentForMacos() =>
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:$firefoxVersion) '
      'Gecko/20100101 Firefox/$firefoxVersion';

  static String normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return defaultUrl;
    }

    final withScheme = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      return defaultUrl;
    }

    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(uri.host)) {
      return defaultUrl;
    }

    return uri.toString();
  }
}
