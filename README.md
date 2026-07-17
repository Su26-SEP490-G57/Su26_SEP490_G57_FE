# POMS Mobile — Flutter App

**Post-Operative Monitoring System** — Ứng dụng mobile theo dõi bệnh nhân sau phẫu thuật, phục vụ 2 vai trò: **Điều dưỡng (Nurse)** và **Bệnh nhân (Patient)**.

---

## Tech Stack

|                  |                                                                         |
| ---------------- | ----------------------------------------------------------------------- |
| Framework        | Flutter 3.44.0 / Dart 3.12.0                                            |
| State management | Riverpod 2.x (`flutter_riverpod`)                                       |
| Navigation       | GoRouter 15.x                                                           |
| Network          | Dio 5.x + 2 custom interceptors                                         |
| Auth             | JWT (access token in-memory, refresh token in SecureStorage)            |
| Local storage    | SharedPreferences (user profile) + FlutterSecureStorage (refresh token) |

---

## Yêu cầu môi trường

| Tool                                                   | Version                   |
| ------------------------------------------------------ | ------------------------- |
| [Dart](https://dart.dev/get-dart#install)              | 3.12.0+                   |
| Flutter                                                | 3.44.0 (quản lý bằng FVM) |
| [Android Studio](https://developer.android.com/studio) | Hedgehog+ (emulator)      |
| JDK                                                    | 17+                       |

---

## Setup

### 1. Clone project

```bash
git clone https://github.com/Su26-SEP490-G57/Su26_SEP490_G57_FE.git
```

### 2. Cài FVM, Flutter, dependencies

> Phiên bản của Flutter đã được cố định trong [`.fvmrc`](./.fvmrc) để đảm bảo mọi người dùng cùng phiên bản, tránh lỗi do khác version.

```bash
dart pub global activate fvm # Nếu chưa có FVM
fvm install

fvm flutter doctor # Kiểm tra setup Flutter, Android SDK, emulator, v.v.
fvm flutter pub get # Cài dependencies
```

### 3. Setup Git Hooks:

Dự án có sử dụng Husky để chạy pre-commit hook, đảm bảo code được format và lint trước khi commit:

```bash
fvm dart run husky install
```

### 4. Tạo file `.env` (Chỉ dùng trên local)

```bash
cp .env.example .env
```

### 5. Chạy app

#### 5.1. Sử dụng command line:

```bash
# Develop
fvm flutter run --flavor dev -t lib/main_dev.dart

# Staging
fvm flutter run --flavor staging -t lib/main_staging.dart

# Production (no debug)
fvm flutter run --flavor prod --release -t lib/main_prod.dart
```

#### 5.2. Đối với VSCode:

- Mở Command Palette (Ctrl+Shift+P) → chọn "Flutter: Select Device" → chọn emulator hoặc thiết bị thật
- Mở Run and Debug view (Ctrl+Shift+D) → chọn một trong 3 cấu hình `Develop (Debug)`, `Staging (Debug)`, `Production (Release)` → nhấn F5 để chạy

## Cấu trúc project

```
lib/
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

## Conventions

- **UI text**: tiếng Việt, dùng `AppStrings` hoặc `const` local — không hardcode inline
- **ShellRoute pages**: không có `Scaffold` riêng — `NurseShell` / `PatientShell` cung cấp
- **Navigation**: `context.go()` cho tabs, `context.push()` cho sub-routes
- **Error handling**: `AppException` ở data layer → map sang `Failure` ở domain
- **Private widgets**: đặt cùng file page (`_WidgetName`), không tách riêng nếu chỉ dùng 1 nơi
