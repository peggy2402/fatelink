# 🧠 Nhật ký phát triển FateLink (Memories)

## 📅 Ngày: 29/03/2026

### 🎯 Trọng tâm hôm nay: Tích hợp xác thực & Tối ưu kiến trúc Frontend

#### 1. Frontend (Flutter)

- **Google Sign-In**: Tích hợp thành công package `google_sign_in` bằng Android client ID thuần (Không dùng Firebase).
- **Khắc phục lỗi ApiException 10**: Giải quyết dứt điểm lỗi cấu hình bảo mật của Google. Đã chốt lại nguyên tắc quan trọng:
  - _Android Client ID_: Google Cloud tự động xác thực ứng dụng qua mã SHA-1 và Package Name. Tuyệt đối không hardcode ID này vào app.
  - _Web Client ID_: Phải dùng ID loại Web truyền vào biến `serverClientId` để Google cấp phát `idToken` (dùng để xác thực với Backend).
- **Refactoring Kiến trúc**: Bóc tách code từ một file `main.dart` nguyên khối sang cấu trúc thư mục chuẩn (`screens/login_screen.dart`), giúp tách biệt logic khởi tạo App và logic của Màn hình đăng nhập.
- **Hệ thống Debug Logging**: Xây dựng hệ thống ghi log cục bộ (`fatelink_logs.txt`) trên thiết bị và hiển thị qua UI Dialog. Giúp theo dõi trực tiếp HTTP request/response và token mà không cần phụ thuộc vào terminal của IDE.

#### 2. Backend (NestJS)

- Luồng xác thực cơ bản đã thành hình: Endpoint `POST /auth/google/login` sẵn sàng nhận `idToken` từ Frontend.
- `AuthModule` đã tích hợp `JwtModule` với cấu hình cấp phát Access Token nội bộ (thời hạn 7 ngày) sau khi xác thực thành công.

#### 3. Triết lý AI của Hệ thống (Nhắc nhớ)

- Luôn bám sát tài liệu `SYSTEMREADME.md` và `PROMPT.md`:
  - Trải nghiệm đăng nhập và Onboarding không dùng "Form điền thông tin" khô khan.
  - AI đóng vai trò người bạn đồng hành tinh tế. Sau bước Login này, người dùng sẽ bước vào luồng trò chuyện tự nhiên để AI bắt đầu quá trình "đọc vị" (phân tích cảm xúc, tính cách) phục vụ cho hệ thống Emotional Matching.

---

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [ ] **Backend**: Cài đặt thư viện `google-auth-library` trong NestJS để verify `idToken` từ Flutter gửi lên, sau đó lưu User Profile vào Database (kèm avatar, email, tên).
- [ ] **Frontend**: Thêm cơ chế quản lý trạng thái (State Management) hoặc bộ nhớ cục bộ (như `flutter_secure_storage`) để lưu JWT token nội bộ mà backend trả về.
- [ ] **Frontend**: Bắt tay vào xây dựng UI cho luồng "AI Onboarding Chat" theo đúng triết lý của FateLink.
