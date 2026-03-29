# 🧠 Nhật ký phát triển FateLink (Memories)

## 📅 Ngày: 29/03/2026

### 🎯 Trọng tâm hôm nay: Hoàn thiện luồng xác thực, Tối ưu UI/UX & Xây dựng tính năng Hỗ trợ người dùng

#### 1. Frontend (Flutter)

- **UI/UX Màn hình Login**:
  - Thiết kế lại toàn bộ giao diện theo phong cách màu nước, sử dụng `Stack` để tạo layout phức tạp với nền gradient chéo và panel bo góc.
  - Thêm hiệu ứng "phát sáng" (Glow) cho text và hiệu ứng "nảy" (Bounce) lặp lại cho nút đăng nhập chính, tăng tính tương tác và thu hút.
  - Tối ưu các chi tiết nhỏ: nút tích điều khoản có hiệu ứng, dải phân cách nét liền, icon social hình tròn.
- **Lưu trữ Token an toàn**: Tích hợp package `flutter_secure_storage` để lưu `accessToken` do backend trả về một cách an toàn, sử dụng Keystore của Android và Keychain của iOS.
- **Tích hợp Splash Screen**: Tùy chỉnh màn hình chờ gốc của Android (`launch_background.xml`) để hiển thị logo và màu sắc thương hiệu ngay khi người dùng mở app.
- **Liên kết Điều khoản**: Sử dụng `url_launcher` để mở các trang web chứa điều khoản dịch vụ, được phục vụ từ chính backend NestJS.

#### 2. Backend (NestJS)

- **Xác thực Google Token**: Cài đặt và cấu hình thành công thư viện `google-auth-library` để xác minh `idToken` từ Flutter gửi lên, đảm bảo tính toàn vẹn và bảo mật.
- **Tối ưu `UsersService`**: Nâng cấp hàm `findOrCreate` sử dụng `findOneAndUpdate` với tùy chọn `upsert: true`, giúp tối ưu hóa việc truy vấn và cập nhật database chỉ trong một lệnh duy nhất.
- **Phục vụ file tĩnh (Static Assets)**:
  - Khắc phục dứt điểm lỗi 404 khi deploy lên Railway bằng cách cấu hình `ServeStaticModule` với `rootPath: join(process.cwd(), 'public')`.
  - Tạo các file HTML chứa nội dung điều khoản (`privacy.html`, `terms.html`...) để Flutter có thể truy cập qua API.
- **Xây dựng Module Hỗ trợ (Support)**:
  - Tạo `SupportModule` riêng biệt theo đúng chuẩn kiến trúc của NestJS.
  - Xây dựng API `POST /support` để nhận dữ liệu từ form hỗ trợ.
  - Tích hợp `class-validator` và `ValidationPipe` toàn cục để tự động kiểm tra dữ liệu đầu vào (email, content không được rỗng...).
  - Kết nối với Discord Webhook để bắn thông báo về các yêu cầu hỗ trợ mới theo thời gian thực, giúp đội ngũ vận hành phản ứng nhanh chóng.

#### 3. Triết lý AI của Hệ thống (Nhắc nhớ)

- Đã hoàn thành bước "đăng nhập" một cách mượt mà. Bước tiếp theo là xây dựng luồng "AI Onboarding Chat" để thực hiện Phase 1: Hiểu người dùng.

---

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [ ] **Frontend**: Xây dựng màn hình chờ (Splash Screen) có logic. Tại đây, kiểm tra xem `accessToken` có tồn tại trong `flutter_secure_storage` hay không. Nếu có, chuyển thẳng vào màn hình chính (Home/Chat). Nếu không, ở lại màn hình Login.
- [ ] **Frontend**: Bắt tay vào xây dựng UI cho luồng "AI Onboarding Chat" theo đúng triết lý đã định nghĩa trong `SYSTEMREADME.md`.
- [ ] **Backend**: Xây dựng `ChatModule` sử dụng WebSocket (Socket.IO hoặc ws) để phục vụ cho việc chat real-time giữa người dùng và AI.
