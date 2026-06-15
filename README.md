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
cp .env.example .env
```

Chỉnh `API_BASE_URL` theo môi trường:

```env
# Android Emulator (default)
API_BASE_URL=http://10.0.2.2:3000

# iOS Simulator
API_BASE_URL=http://127.0.0.1:3000

# Thiết bị thực (cùng WiFi với máy chạy BE)
API_BASE_URL=http://<IP_máy_host>:3000
```

> BE NestJS không có global prefix. Swagger UI ở `http://localhost:3000/api`.
> Sau khi đổi `.env` phải hot restart (`R`), không phải hot reload (`r`).

### 3. Chạy app

```bash
# Android emulator / thiết bị thực
flutter run

# Windows desktop
flutter run -d windows
```

---

## Cấu trúc project

```
fe/lib/
├── core/
│   ├── constants/      # AppColors, AppConstants, AppRoutes, AppStrings, AppTextStyles
│   ├── errors/         # AppException (sealed), Failure (sealed)
│   ├── network/        # dio_client, token_storage, interceptors, api_response
│   ├── router/         # GoRouter config + redirect logic
│   ├── theme/          # AppTheme — Material 3, Inter font
│   └── utils/          # extensions, exception_handler
├── features/
│   ├── auth/           # data / domain / presentation
│   ├── nurse/          # domain + presentation (Dashboard, Patients, Detail...)
│   └── patient/        # presentation (Dashboard, Assessment, Profile...)
└── shared/widgets/     # AppButton, AppTextField, ErrorView, LoadingOverlay
```

---

## Lệnh thường dùng

```bash
flutter pub get                                          # cài dependencies
flutter run                                             # chạy app
flutter analyze lib                                     # static analysis
dart run build_runner build --delete-conflicting-outputs # code generation
flutter clean && flutter pub get                        # clean build cache
```

---

## Conventions

- **UI text**: tiếng Việt, dùng `AppStrings` hoặc `const` local — không hardcode inline
- **ShellRoute pages**: không có `Scaffold` riêng — `NurseShell` / `PatientShell` cung cấp
- **Navigation**: `context.go()` cho tabs, `context.push()` cho sub-routes
- **Error handling**: `AppException` ở data layer → map sang `Failure` ở domain
- **Private widgets**: đặt cùng file page (`_WidgetName`), không tách riêng nếu chỉ dùng 1 nơi
