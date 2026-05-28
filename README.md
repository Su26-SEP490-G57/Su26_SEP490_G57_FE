# POMS Mobile — Flutter App

Post-Operative Monitoring System — Mobile app cho **Nurse** và **Patient**.

---

## Yêu cầu

| Tool | Version |
|---|---|
| Flutter | 3.38.6+ |
| Dart | 3.10.7+ |
| Android Studio | Hedgehog+ (để chạy emulator) |
| Node.js | 18+ (chỉ cần cho scripts Firebase) |

---

## Setup

### 1. Clone & cài dependencies

```bash
git clone https://github.com/Su26-SEP490-G57/Su26_SEP490_G57_FE.git
cd fe
flutter pub get
```

### 2. Cấu hình Firebase

**Android:** File `android/app/google-services.json`.

**iOS:** Cần thêm `ios/Runner/GoogleService-Info.plist` — download từ Firebase Console nếu build iOS.

**Tất cả platform:** Firebase options đã được cấu hình trong `lib/firebase_options.dart`.

### 3. Tạo file `.env`

```bash
cp .env.example .env  # hoặc tạo thủ công
```

Nội dung `.env`:
```
API_BASE_URL=http://10.0.2.2:8080/api
```

> `10.0.2.2` là địa chỉ localhost của máy host khi chạy trên Android emulator.

### 4. Chạy app

```bash
# Chạy trên emulator/device
flutter run

# Chạy trên Windows desktop (để test nhanh)
flutter run -d windows
```

---

## Tạo tài khoản test (Nurse)

Firebase Auth chỉ hỗ trợ Email/Password. Nurse login dùng email ảo theo format `<username>@poms.internal`.

**Bước 1:** Vào [Firebase Console](https://console.firebase.google.com) → project `project cua ban` → Authentication → Users → Add user
- Email: `.....@poms.internal`
- Password: `.....`

**Bước 2:** Cài script để set custom claims (nếu cần test role):
```bash
cd scripts
npm install
# Download serviceAccountKey.json từ Firebase Console → Project Settings → Service accounts
node set-role.js nurse01@poms.internal nurse
```

**Bước 3:** Login trong app với username `nurse01` / password `Nurse@123`.

---

## Cấu trúc project

```
lib/
  core/
    constants/     # màu sắc, typography, routes, strings
    errors/        # exception & failure classes
    network/       # Dio client, auth interceptor
    router/        # GoRouter config
    theme/         # AppTheme (Material 3)
    utils/         # extensions, exception handler

  features/
    auth/          # login, auth state, Firebase auth
    nurse/         # nurse dashboard, patient list, alerts, tasks, profile
    patient/       # patient dashboard (placeholder)

  shared/
    widgets/       # AppButton, AppTextField, CustomCheckbox, ErrorView...

  app.dart         # MaterialApp.router
  main.dart        # entry point
  firebase_options.dart
```

---

## Lệnh thường dùng

```bash
flutter pub get          # cài dependencies
flutter run              # chạy app
flutter run -d windows   # chạy trên Windows
flutter analyze lib      # kiểm tra lỗi static
flutter clean            # clean build cache
```
