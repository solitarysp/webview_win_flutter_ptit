# webview_win_flutter

Ứng dụng Flutter desktop truy cập website bằng WebView, hỗ trợ **Windows + macOS**.

## Tính năng
- Mở website mặc định: `https://www.google.com`
- Có ô nhập URL để đổi website
- Nút **Mở** và **Tải lại**
- Hiển thị trạng thái loading
- Báo lỗi tải trang
- Windows: kiểm tra và báo thiếu WebView2 Runtime

## Yêu cầu
- Flutter stable
- Windows 10 1809+ (cần Microsoft Edge WebView2 Runtime)
- macOS 10.14+

## Chạy app
```bash
flutter pub get
flutter run -d windows
flutter run -d macos
```

## Kiểm tra chất lượng
```bash
flutter analyze --no-pub
flutter test --no-pub
```
