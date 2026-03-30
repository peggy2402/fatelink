# 🧠 Nhật ký phát triển FateLink (Memories)

## 📅 Ngày: 30/03/2026

### 🎯 Trọng tâm hôm nay: Hoàn thiện luồng xác thực, Tối ưu UI/UX & Xây dựng tính năng Hỗ trợ người dùng

#### 1. Frontend (Flutter)

- **UI/UX Màn hình Login**:
  - Thiết kế lại toàn bộ giao diện theo phong cách màu nước, sử dụng `Stack` để tạo layout phức tạp với nền gradient chéo và panel bo góc.
  - Thêm hiệu ứng "phát sáng" (Glow) cho text và hiệu ứng "nảy" (Bounce) lặp lại cho nút đăng nhập chính, tăng tính tương tác và thu hút.
  - Tối ưu các chi tiết nhỏ: nút tích điều khoản có hiệu ứng, dải phân cách nét liền, icon social hình tròn.
- **Lưu trữ Token an toàn**: Tích hợp package `flutter_secure_storage` để lưu `accessToken` do backend trả về một cách an toàn, sử dụng Keystore của Android và Keychain của iOS.
- **Tích hợp Splash Screen**:
  - Tùy chỉnh màn hình chờ gốc của Android (`launch_background.xml`).
  - Nâng cấp `splash_screen.dart` thành phiên bản "Cinematic" với nền Deep Burgundy gradient, hạt Bokeh lơ lửng, Logo Glassmorphism và hiệu ứng animation (Fade/Scale) mượt mà.
  - Tích hợp logic kiểm tra `accessToken` để tự động điều hướng (Auto-login).
- **Màn hình Welcome (AI Onboarding)**: Xây dựng `WelcomeScreen` theo phong cách "app store story card" cao cấp. Giao diện sử dụng nền Frosted Glass, khung hình quả trứng hữu cơ chứa Avatar Faye AI, typography thanh lịch. Định tuyến mượt mà: Splash -> Login -> Welcome.
- **Liên kết Điều khoản**: Sử dụng `url_launcher` để mở các trang web chứa điều khoản dịch vụ, được phục vụ từ chính backend NestJS.
- **Màn hình Chat (Faye AI)**: Hoàn thiện `chat_screen.dart` với giao diện bong bóng chat tinh tế, có thời gian (timestamp), hiệu ứng AI đang gõ (Typing indicator), và tích hợp `socket_io_client` để trò chuyện thời gian thực. Bổ sung tính năng tự động tải lịch sử chat cũ khi mở màn hình.
- **Thanh Điều Hướng (Custom Bottom Nav Bar)**: Tạo widget `CustomBottomNavBar` sử dụng hiệu ứng Glassmorphism (kính mờ) và đổ bóng phát sáng (Glow shadow) cho các icon được chọn.
- **Màn hình Trang chủ (Home Screen)**: Xây dựng UI `home_screen.dart` theo chuẩn Premium Dark Theme kết hợp Mesh Gradient. Thiết kế các "Thẻ người dùng ẩn danh" với Avatar AI có hiệu ứng nhịp thở (Breathing light) và biểu đồ sóng tần số cảm xúc được mã hóa màu.

#### 2. Backend (NestJS)

- **Xác thực Google Token**: Cài đặt và cấu hình thành công thư viện `google-auth-library` để xác minh `idToken` từ Flutter gửi lên, đảm bảo tính toàn vẹn và bảo mật.
- **Tối ưu `UsersService`**: Nâng cấp hàm `findOrCreate` sử dụng `findOneAndUpdate` với tùy chọn `upsert: true`, giúp tối ưu hóa việc truy vấn và cập nhật database chỉ trong một lệnh duy nhất.
- **Cập nhật Cảm xúc (Emotion Tracking)**: Thêm phương thức `updateEmotion` vào `UsersService` sử dụng Mongoose để lưu trữ trạng thái cảm xúc của người dùng theo thời gian thực.
- **Phục vụ file tĩnh (Static Assets)**:
  - Khắc phục dứt điểm lỗi 404 khi deploy lên Railway bằng cách cấu hình `ServeStaticModule` với `rootPath: join(process.cwd(), 'public')`.
  - Tạo các file HTML chứa nội dung điều khoản (`privacy.html`, `terms.html`...) để Flutter có thể truy cập qua API.
- **Xây dựng Module Hỗ trợ (Support)**:
  - Tạo `SupportModule` riêng biệt theo đúng chuẩn kiến trúc của NestJS.
  - Xây dựng API `POST /support` để nhận dữ liệu từ form hỗ trợ.
  - Tích hợp `class-validator` và `ValidationPipe` toàn cục để tự động kiểm tra dữ liệu đầu vào (email, content không được rỗng...).
  - Kết nối với Discord Webhook để bắn thông báo về các yêu cầu hỗ trợ mới theo thời gian thực, giúp đội ngũ vận hành phản ứng nhanh chóng.
- **Real-time Chat & AI Integration**:
  - Xây dựng `MessageModule` dùng MongoDB (Mongoose) để lưu trữ và truy xuất lịch sử tin nhắn.
  - Tích hợp WebSocket thông qua `ChatGateway`, cho phép giao tiếp thời gian thực, tự động giải mã JWT để lấy `userId`.
  - Nâng cấp `GeminiService` để đóng vai trò AI Onboarding, ép buộc trả về cấu trúc JSON (`reply`, `detected_emotion`, `is_ready_to_match`) để Backend có thể vừa chat vừa tự động cập nhật Database.

#### 3. Triết lý AI của Hệ thống (Nhắc nhớ)

- Đã hoàn thành bước "đăng nhập" một cách mượt mà. Bước tiếp theo là xây dựng luồng "AI Onboarding Chat" để thực hiện Phase 1: Hiểu người dùng.

---

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [x] **Frontend**: Xây dựng màn hình chờ (Splash Screen) có logic auto-login.
- [x] **Frontend**: Xây dựng UI màn hình Welcome để chuẩn bị Onboarding.
- [x] **Frontend**: Thiết kế `chat_screen.dart` với khung chat tinh tế để bắt đầu nói chuyện với Faye AI.
- [x] **Backend**: Xây dựng `ChatModule` sử dụng WebSocket (Socket.IO hoặc ws) để phục vụ cho việc chat real-time giữa người dùng và AI.
- [ ] **Frontend & Backend**: Liên kết Bottom Navigation Bar (điều hướng thực tế giữa các tab Home, Chat, Matches, Profile).
- [ ] **Backend**: Viết API GET trả về danh sách người dùng ẩn danh cho `HomeScreen` dựa trên thuật toán Matchmaking sơ bộ.
