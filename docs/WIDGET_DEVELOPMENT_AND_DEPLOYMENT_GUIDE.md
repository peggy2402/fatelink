# Hướng Dẫn Phát Triển, Kiểm Thử & Triển Khai Tiện Ích Màn Hình (Native Widgets) - FateLink

> **Tài liệu lưu trữ:** Hướng dẫn chi tiết kiến trúc Widget (Android & iOS), quy trình kiểm thử hoàn toàn **miễn phí 100%** (không cần chi phí $99 Apple Developer và $25 Google Play), và checklist sẵn sàng cho ngày phát hành chính thức.

---

## 1. Tổng Quan Kiến Trúc Widget (Cosmic Soulmate Glance)

Tiện ích màn hình chính của FateLink mang tên **Cosmic Soulmate Glance** (Tri kỷ Tâm hồn FateLink), có nhiệm vụ cập nhật tự động tần số cảm xúc và người đồng điệu tâm hồn gần nhất lên màn hình khóa và màn hình chính của người dùng.

```
       ┌────────────────────────────────────────────────────────┐
       │                 Flutter App (Dart)                     │
       │    CosmicWidgetService / HomeBloc / MatchesBloc        │
       └──────────────────────────┬─────────────────────────────┘
                                  │
                  Lưu dữ liệu qua key-value store
                                  │
            ┌─────────────────────┴─────────────────────┐
            ▼                                           ▼
┌───────────────────────┐                   ┌───────────────────────┐
│     Android OS        │                   │        iOS            │
│   SharedPreferences   │                   │  Shared App Group     │
│           │           │                   │  (UserDefaults)       │
│           ▼           │                   │           │           │
│ AppWidgetProvider     │                   │           ▼           │
│ (RemoteViews Layout)  │                   │ WidgetKit (SwiftUI)   │
└───────────────────────┘                   └───────────────────────┘
```

### Các tập tin đã cấu hình trong dự án:

1. **Flutter Service:**
   - [`lib/services/cosmic_widget_service.dart`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/lib/services/cosmic_widget_service.dart): Cầu nối lưu trữ dữ liệu và gửi tín hiệu vẽ lại Widget.
   - [`lib/logic/blocs/home/home_bloc.dart`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/lib/logic/blocs/home/home_bloc.dart): Tự động đồng bộ tri kỷ tâm hồn mới nhất khi nạp danh sách kết nối.

2. **Android Native:**
   - [`android/app/src/main/res/xml/cosmic_soulmate_widget_info.xml`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/android/app/src/main/res/xml/cosmic_soulmate_widget_info.xml): Metadata định danh Widget.
   - [`android/app/src/main/res/layout/cosmic_soulmate_widget.xml`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/android/app/src/main/res/layout/cosmic_soulmate_widget.xml): Giao diện Widget theo chuẩn thiết kế Cosmic Dark Mode.
   - [`android/app/src/main/res/drawable/cosmic_widget_background.xml`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/android/app/src/main/res/drawable/cosmic_widget_background.xml): Nền bo góc mềm mại 24dp viền Indigo.
   - [`android/app/src/main/kotlin/com/example/fatelinkfe/CosmicSoulmateWidgetProvider.kt`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/android/app/src/main/kotlin/com/example/fatelinkfe/CosmicSoulmateWidgetProvider.kt): Broadcast Receiver xử lý cập nhật giao diện và deep link.
   - [`android/app/src/main/AndroidManifest.xml`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/android/app/src/main/AndroidManifest.xml): Đăng ký Receiver và Deep link `fatelink://match`.

3. **iOS Native:**
   - [`ios/Runner/CosmicSoulmateGlanceWidget.swift`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/ios/Runner/CosmicSoulmateGlanceWidget.swift): Viết bằng SwiftUI & WidgetKit hỗ trợ widget kích thước Small & Medium.
   - [`ios/Runner/Info.plist`](file:///Users/peggy2402/Projects/fatelink/fatelinkfe/ios/Runner/Info.plist): Đăng ký URL Schemes `fatelink`.

---

## 2. Bảng Định Danh Kỹ Thuật (Data Mapping Keys)

| Khóa Dữ Liệu | Kiểu Dữ Liệu | Ý Nghĩa | Giá Trị Mặc Định Fallback |
| :--- | :--- | :--- | :--- |
| `headline` | `String` | Tiêu đề Widget kèm tần số | `✦ FATELINK 432Hz` |
| `soulmate_name` | `String` | Tên hoặc bí danh tri kỷ | `Tri kỷ FateLink` |
| `soulmate_vibe` | `String` | Cảm xúc / Tần số hòa âm | `Đang hòa âm tần số 432 Hz` |
| `soulmate_harmony` | `String` | Tỷ lệ tương thích | `95% Hòa âm` |
| `soulmate_distance` | `String` | Khoảng cách địa lý thực | `📍 Đang ở gần bạn` |

* **Deep link khi chạm vào Widget:** `fatelink://match` (mở thẳng vào màn hình Kết nối / Quét sóng tâm hồn).

---

## 3. Hướng Dẫn Kiểm Thử Miễn Phí 100% (Zero Cost)

> [!TIP]
> Bạn **HOÀN TOÀN KHÔNG CẦN** mua tài khoản $99 Apple Developer hay $25 Google Play Developer trong suốt quá trình lập trình, kiểm thử và demo cho bạn bè/nhà đầu tư.

### A. Kiểm thử trên Android (Máy thật & Máy ảo)

Hệ điều hành Android cho phép cài đặt và chạy Widget trực tiếp mà không cần bất kỳ giấy phép trả phí nào:

1. **Chạy ứng dụng từ Terminal:**
   ```bash
   cd /Users/peggy2402/Projects/fatelink/fatelinkfe
   flutter run -d android
   ```
2. **Thêm Widget ra màn hình:**
   - Nhấn và giữ một vị trí trống bất kỳ trên Màn hình chính của điện thoại Android.
   - Chọn mục **Tiện ích (Widgets)**.
   - Cuộn tìm ứng dụng **Meyu** (hoặc **FateLink**).
   - Chọn tiện ích **Tri kỷ Tâm hồn FateLink** và kéo thả ra màn hình chính.
   - Mở ứng dụng, kéo làm mới danh sách kết nối tại Trang chủ -> Widget trên màn hình chính sẽ tự động đổi tên và chỉ số hòa âm theo người mới nhất!

---

### B. Kiểm thử trên iOS (Máy ảo Simulator)

iOS Simulator trên macOS cho phép chạy WidgetKit 100% miễn phí mà không cần tài khoản Apple Developer:

1. **Khởi chạy iPhone Simulator:**
   ```bash
   open -a Simulator
   cd /Users/peggy2402/Projects/fatelink/fatelinkfe
   flutter run -d iPhone
   ```
2. **Thêm Widget trên Simulator:**
   - Nhấn giữ màn hình chính máy ảo cho đến khi các icon rung lắc (Jiggle mode).
   - Nhấn dấu **`+`** ở góc trên cùng bên trái màn hình.
   - Tìm kiếm **Meyu** / **FateLink** -> Chọn kích thước Widget mong muốn (Small hoặc Medium) -> Bấm **Add Widget**.

---

### C. Kiểm thử trên iPhone Thật bằng Tài Khoản Apple ID Cá Nhân (Free Personal Team)

Apple cho phép dùng bất kỳ tài khoản Apple ID miễn phí nào để nạp app lên iPhone cá nhân thông qua cáp USB:

1. Cắm iPhone vào máy Mac bằng cáp USB.
2. Mở thư mục iOS trong Xcode:
   ```bash
   open /Users/peggy2402/Projects/fatelink/fatelinkfe/ios/Runner.xcworkspace
   ```
3. Trong Xcode, chọn project **Runner** ở cột trái -> chọn tab **Signing & Capabilities**.
4. Tại mục **Team**: Chọn tài khoản Apple ID cá nhân của bạn (ví dụ: `Your Name (Personal Team)`).
   *(Nếu chưa có, vào Xcode -> Settings -> Accounts -> bấm `+` đăng nhập Apple ID miễn phí).*
5. Chọn thiết bị đích là iPhone của bạn và bấm nút **Play (Run)**.
6. Trên iPhone: Vào **Cài đặt -> Cài đặt chung -> Quản lý VPN & Thiết bị** -> Bấm **Tin cậy (Trust)** chứng chỉ cá nhân của bạn là ứng dụng và Widget sẽ hoạt động ngay.

---

## 4. Checklist Khi Có Chi Phí Đăng Ký Tài Khoản Developer

Khi bạn đã sẵn sàng phát hành ứng dụng lên App Store và Google Play, hãy thực hiện các bước cấu hình sau:

### 1. Tài khoản Google Play Developer ($25 trả một lần):
- [ ] Đăng ký tại [Google Play Console](https://play.google.com/console).
- [ ] Tạo Keystore ký mã phát hành (`upload-keystore.jks`).
- [ ] Chạy lệnh đóng gói: `flutter build appbundle --release`.
- [ ] Tải file `.aab` lên Google Play Console để gửi duyệt (Không cần cấu hình thêm bất kỳ cài đặt đặc thù nào cho Widget trên Android).

### 2. Tài khoản Apple Developer Program ($99/năm):
- [ ] Đăng ký tại [Apple Developer Program](https://developer.apple.com/programs/).
- [ ] **Kích hoạt App Group Container:**
  1. Vào cổng [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
  2. Tạo một **App Group** mới với định danh: `group.com.fatelink.app`.
  3. Gán App Group này vào App ID chính (`com.example.fatelinkfe` hoặc Bundle ID chính thức của bạn).
  4. Trong Xcode -> Tab **Signing & Capabilities** của target `Runner`: Bấm `+ Capability` -> Chọn **App Groups** -> Tích chọn `group.com.fatelink.app`.
- [ ] Đóng gói và phát hành: `flutter build ipa` và tải lên App Store Connect qua Transporter hoặc Xcode.

---

## 5. Tóm Tắt Trạng Thái Hiện Tại Của Dự Án

| Tính Năng | Trạng Thái Kỹ Thuật | Chi Phí Phát Sinh |
| :--- | :--- | :--- |
| **Android AppWidget Layout & Provider** | Hoàn thành 100%, sẵn sàng chạy ngay | **0 VNĐ** |
| **iOS WidgetKit SwiftUI View** | Hoàn thành 100%, sẵn sàng chạy trên Simulator | **0 VNĐ** |
| **CosmicWidgetService Đồng bộ dữ liệu** | Hoàn thành 100%, tích hợp sẵn vào `HomeBloc` | **0 VNĐ** |
| **Backend Tương tác & Thông báo (Fly.io)** | Đã deploy và kích hoạt live trên production | Sử dụng Free/Current Plan |
