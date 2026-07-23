String buildWindowsWebLoadErrorMessage(String rawStatus) {
  final compact = rawStatus.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  const knownMessages = <String, String>{
    'connectionaborted': 'Kết nối bị hủy giữa chừng.',
    'connectionreset': 'Kết nối bị đặt lại.',
    'hostnamenotresolved': 'Không phân giải được tên miền.',
    'serverunreachable': 'Không thể kết nối tới máy chủ.',
    'cannotconnect': 'Không thể thiết lập kết nối.',
    'timeout': 'Hết thời gian chờ phản hồi từ máy chủ.',
    'disconnected': 'Thiết bị đang mất kết nối mạng.',
    'operationcanceled': 'Yêu cầu đã bị hủy.',
    'redirectfailed': 'Chuyển hướng trang thất bại.',
    'certificateexpired': 'Chứng chỉ bảo mật đã hết hạn.',
    'certificateisinvalid': 'Chứng chỉ bảo mật không hợp lệ.',
    'certificaterevoked': 'Chứng chỉ bảo mật đã bị thu hồi.',
    'unexpectederror': 'Đã xảy ra lỗi không xác định.',
  };

  for (final entry in knownMessages.entries) {
    if (compact.contains(entry.key)) {
      return 'Không tải được trang: ${entry.value}';
    }
  }

  return 'Không tải được trang: $rawStatus';
}
