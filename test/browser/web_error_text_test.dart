import 'package:flutter_test/flutter_test.dart';
import 'package:webview_win_flutter/browser/web_error_text.dart';

void main() {
  test('maps connection aborted to friendly Vietnamese message', () {
    final message = buildWindowsWebLoadErrorMessage(
      'webErrorStatus.webErrorStatusConnectionAborted',
    );

    expect(message, 'Không tải được trang: Kết nối bị hủy giữa chừng.');
  });

  test('maps timeout status to friendly Vietnamese message', () {
    final message = buildWindowsWebLoadErrorMessage('WebErrorStatus.timeout');

    expect(
      message,
      'Không tải được trang: Hết thời gian chờ phản hồi từ máy chủ.',
    );
  });

  test('keeps raw status when status is unknown', () {
    final message = buildWindowsWebLoadErrorMessage('strange_error_code_123');

    expect(message, 'Không tải được trang: strange_error_code_123');
  });
}
