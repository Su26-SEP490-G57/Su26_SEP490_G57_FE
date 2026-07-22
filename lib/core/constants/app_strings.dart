/// App-wide string constants
/// todo: Replace with flutter_localizations when i18n is needed
abstract final class AppStrings {
  // App
  static const String appName = 'POMS';
  static const String appFullName = 'Post-Operative Monitoring System';

  // Auth
  static const String login = 'Đăng nhập';
  static const String logout = 'Đăng xuất';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String emailHint = 'Nhập email của bạn';
  static const String passwordHint = 'Nhập mật khẩu';
  static const String loginButton = 'Đăng nhập';
  static const String loginFailed = 'Đăng nhập thất bại';
  static const String invalidEmail = 'Email không hợp lệ';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const String fieldRequired = 'Trường này không được để trống';

  // Navigation
  static const String home = 'Trang chủ';
  static const String monitoring = 'Theo dõi';
  static const String alerts = 'Cảnh báo';
  static const String profile = 'Hồ sơ';
  static const String patients = 'Bệnh nhân';
  static const String notifications = 'Thông báo';

  // Common
  static const String loading = 'Đang tải...';
  static const String retry = 'Thử lại';
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String delete = 'Xóa';
  static const String edit = 'Chỉnh sửa';
  static const String back = 'Quay lại';
  static const String noData = 'Không có dữ liệu';
  static const String unknownError = 'Đã xảy ra lỗi. Vui lòng thử lại.';
  static const String networkError =
      'Lỗi kết nối mạng. Kiểm tra internet và thử lại.';
  static const String sessionExpired =
      'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
}
