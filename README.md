# POMS Mobile — Flutter App

**Post-Operative Monitoring System** — Ứng dụng mobile theo dõi bệnh nhân sau phẫu thuật, phục vụ 2 vai trò: **Điều dưỡng (Nurse)** và **Bệnh nhân (Patient)**.

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter 3.44.0 / Dart 3.12.0 |
| State management | Riverpod 2.x (`flutter_riverpod`) |
| Navigation | GoRouter 15.x |
| Network | Dio 5.x + 2 custom interceptors |
| Auth | JWT (access token in-memory, refresh token in SecureStorage) |
| Local storage | SharedPreferences (user profile) + FlutterSecureStorage (refresh token) |

---

## Yêu cầu môi trường

| Tool | Version |
|---|---|
| Flutter | 3.44.0+ |
| Dart | 3.12.0+ |
| Android Studio | Hedgehog+ (emulator) |
| JDK | 17+ |

---

## Setup

### 1. Clone & cài dependencies

```bash
git clone https://github.com/Su26-SEP490-G57/Su26_SEP490_G57_FE.git
cd fe
flutter pub get
```

### 2. Tạo file `.env`

```bash
# Tạo file .env trong thư mục fe/
cp .env.example .env
```

Nội dung `.env`:

```env
API_BASE_URL=http://10.0.2.2:8080/api
```

> `10.0.2.2` là địa chỉ trỏ về `localhost` của máy host khi chạy Android Emulator.
> Thay bằng IP thực nếu dùng thiết bị vật lý hoặc deploy lên server.

### 3. Chạy app

```bash
# Android emulator / thiết bị thực
flutter run

# Windows desktop (test nhanh không cần emulator)
flutter run -d windows
```

---

## Cấu trúc project

```
fe/lib/
├── core/
│   ├── constants/      # AppColors, AppConstants, AppRoutes, AppStrings, AppTextStyles
│   ├── errors/         # AppException (sealed), Failure (sealed)
│   ├── network/        # dio_client, token_storage, access_token_interceptor,
│   │                   # refresh_token_interceptor, api_response
│   ├── router/         # GoRouter config + redirect logic
│   ├── theme/          # AppTheme — Material 3, Inter font
│   └── utils/          # extensions, exception_handler
│
├── features/
│   ├── auth/
│   │   ├── data/       # AuthRemoteDataSource (REST), AuthRepositoryImpl
│   │   ├── domain/     # UserModel, UserRole, AuthRepository interface
│   │   └── presentation/ # LoginPage, SplashPage, auth_provider, login widgets
│   ├── nurse/
│   │   ├── domain/     # PatientSummary, PatientStatus, kMockPatients
│   │   └── presentation/
│   │       ├── layouts/  # NurseShell (bottom nav)
│   │       └── pages/    # Dashboard, Patients, PatientDetail, Alerts,
│   │                     # Reports, Tasks, Profile
│   └── patient/
│       └── presentation/ # PatientDashboardPage (stub)
│
├── shared/
│   └── widgets/        # AppButton, AppTextField, CustomCheckbox,
│                       # ErrorView, LoadingOverlay
│
├── app.dart            # MaterialApp.router
└── main.dart           # Entry point
```

---

## Auth Flow

App dùng **JWT thuần** (không Firebase Auth):

```
Login  →  POST /auth/login  →  { accessToken, refreshToken, user }
                               ↓
                 accessToken  →  in-memory (mất khi app kill)
                 refreshToken →  FlutterSecureStorage
                 user profile →  SharedPreferences (JSON)

Request  →  AccessTokenInterceptor gắn Bearer header
   401   →  RefreshTokenInterceptor gọi POST /auth/refresh
            → nhận accessToken mới → retry original request
            → nếu refresh thất bại → logout + redirect /login
```

**Remember Me:**
- Tick → giữ session qua app restart (restore từ SharedPreferences)
- Không tick → xóa session ngay khi app khởi động lại

---

## Lệnh thường dùng

```bash
# Cài / cập nhật dependencies
flutter pub get

# Chạy app
flutter run
flutter run -d windows

# Static analysis
flutter analyze lib

# Code generation (Riverpod, Freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Clean build cache
flutter clean && flutter pub get
```

---

## Conventions

- **Tất cả UI text**: tiếng Việt, khai báo trong `AppStrings` hoặc `const` local
- **Page trong ShellRoute** (nurse): không có `Scaffold` riêng — `NurseShell` cung cấp
- **Navigation**: `context.go()` cho tabs, `context.push()` cho sub-routes
- **Error handling**: throw `AppException` ở data layer, map sang `Failure` ở domain
- **Private widgets**: đặt cùng file với page (`_WidgetName`), không tách file riêng trừ khi dùng nhiều nơi

---

## Trạng thái hiện tại

| Feature | Status |
|---|---|
| Auth (JWT login/logout/refresh/session restore) | ✅ Hoàn chỉnh |
| Nurse Dashboard | ✅ UI xong, data mock |
| Nurse Patient List (search + filter) | ✅ UI xong, data mock |
| Nurse Patient Detail (tab Tổng quan) | ✅ UI xong, data mock |
| Nurse Patient Detail (4 tabs còn lại) | 🚧 Placeholder |
| Nurse Alerts / Reports / Tasks | 🚧 Placeholder |
| Patient feature | 🚧 Placeholder |
| API integration (thay mock data) | ⏳ Chờ backend |
| Push notification (FCM) | ⏳ Chờ backend |
