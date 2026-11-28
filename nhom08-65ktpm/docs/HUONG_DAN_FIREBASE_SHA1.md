# Hướng Dẫn Kết Nối Firebase & Thêm Mã SHA-1 Cho Thành Viên Nhóm 08

Tài liệu này hướng dẫn các thành viên trong nhóm cách kết nối máy cá nhân với dự án Firebase chung của **Travel Buddy** và bổ sung mã **SHA-1** để chạy các tính năng xác thực (như Google Sign-In, Firebase Auth) trên Android.

---

## 1. Thông tin Firebase chung của dự án

- **Firebase Project ID:** `travel-buddy-flutter`
- **Android Application ID:** `vn.edu.tlu.travel_buddy`
- **Các tệp cấu hình đã có trong mã nguồn (`nhom08-65ktpm/src/`):**
  - `firebase.json`
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`

> **Lưu ý:** Trưởng nhóm cần mời tài khoản Google (Gmail) của từng thành viên vào dự án `travel-buddy-flutter` trên Firebase Console (**Project settings → Users and permissions → Add member**) với quyền tối thiểu là **Editor** để thành viên tự thêm được mã SHA-1.

---

## 2. Lấy mã SHA-1 trên máy cá nhân

Mỗi máy tính build app Android ở chế độ debug sẽ có một tệp `debug.keystore` riêng với mã SHA-1 khác nhau. Thực hiện một trong hai cách dưới đây để lấy mã SHA-1 của máy bạn:

### Cách 1: Dùng Gradle `signingReport` (khuyên dùng nếu đã cài Android SDK)

- **Windows (PowerShell):**
  ```powershell
  cd nhom08-65ktpm/src/android
  .\gradlew.bat signingReport
  ```
- **macOS / Linux:**
  ```bash
  cd nhom08-65ktpm/src/android
  ./gradlew signingReport
  ```

Tìm khối **`Variant: debug`** / **`Config: debug`** trong kết quả in ra và sao chép dòng **`SHA1:`** (và **`SHA-256:`** nếu cần).

> *Mẹo xử lý lỗi:* Nếu Gradle báo lỗi kiểm tra phiên bản tối thiểu của Flutter Gradle Plugin, hãy chạy kèm cờ `-PskipDependencyChecks=true`:
> ```powershell
> .\gradlew.bat signingReport -PskipDependencyChecks=true
> ```

### Cách 2: Dùng `keytool` trực tiếp (nhanh, không cần Gradle/Android SDK)

- **Windows (PowerShell):**
  ```powershell
  keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  ```
- **macOS / Linux:**
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```

**Trường hợp máy báo chưa tìm thấy `debug.keystore`** (do chưa từng build Android trên máy): hãy tạo tệp `debug.keystore` chuẩn Android trước, rồi chạy lại lệnh `-list` ở trên:

- **Windows (PowerShell):**
  ```powershell
  keytool -genkeypair -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  ```
- **macOS / Linux:**
  ```bash
  keytool -genkeypair -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  ```

> *Lưu ý:* Nếu `keytool` chưa có trong `PATH`, hãy chạy trực tiếp từ thư mục JDK 17 đã cài (ví dụ: `C:\Program Files\Eclipse Adoptium\jdk-17...\bin\keytool.exe` hoặc `jbr\bin\keytool.exe` trong thư mục Android Studio).

---

## 3. Thêm mã SHA-1 lên Firebase Console

1. Đăng nhập [Firebase Console](https://console.firebase.google.com/) bằng tài khoản Google đã được cấp quyền.
2. Chọn dự án **`travel-buddy-flutter`**.
3. Nhấn biểu tượng bánh răng (**Project settings**) → tab **General**.
4. Kéo xuống mục **Your apps**, chọn ứng dụng Android **`vn.edu.tlu.travel_buddy`**.
5. Nhấn **Add fingerprint**.
6. Dán mã **SHA-1** (định dạng `XX:XX:...`) vừa lấy ở Bước 2 vào và nhấn **Save**.
   *(Khuyến nghị thêm cả **SHA-256** tương ứng của máy bạn).*

> **Kiểm tra thêm cho Google Sign-In:** Trong mục **Authentication → Sign-in method**, đảm bảo đã bật **Email/Password** và **Google** (đã chọn **Support email** cho dự án).

---

## 4. Đồng bộ lại tệp `google-services.json`

Sau khi thêm SHA-1 mới lên Firebase Console, Firebase sẽ cập nhật lại thông tin OAuth client trong cấu hình Android:

1. Tại trang **Project settings → Your apps → `vn.edu.tlu.travel_buddy`**, nhấn **Download `google-services.json`**.
2. Ghi đè tệp vừa tải vào đường dẫn:
   ```text
   nhom08-65ktpm/src/android/app/google-services.json
   ```
3. *(Tùy chọn nếu dùng FlutterFire CLI)* Có thể chạy lại:
   ```bash
   cd nhom08-65ktpm/src
   flutterfire configure --project=travel-buddy-flutter
   ```

---

## 5. Kiểm tra và chạy thử ứng dụng

```bash
cd nhom08-65ktpm/src
flutter pub get
flutter analyze
flutter run
```

---

## 6. Lưu ý khi làm việc nhóm với Git

- Luôn kéo code mới nhất (`git pull`) trước khi cập nhật `google-services.json` hoặc `firebase_options.dart` để tránh xung đột.
- Chỉ stage thư mục của nhóm khi commit theo đúng quy định của học phần:
  ```bash
  git add nhom08-65ktpm/
  ```
- Không commit file `debug.keystore` cá nhân lên kho lưu trữ.
