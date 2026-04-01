# 🧠 Nhật ký phát triển FateLink (Memories)

## 📅 Ngày: 30/03/2026 (Cập nhật lần 2)

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
- **Liên kết Điều khoản**: Sử dụng `url_launcher` để mở các trang web chứa điều khoản dịch vụ, được phục vụ từ chính backend NestJS.
- **Màn hình Chat (Faye AI)**: Hoàn thiện `chat_screen.dart` với giao diện bong bóng chat tinh tế, có thời gian (timestamp), hiệu ứng AI đang gõ (Typing indicator), và tích hợp `socket_io_client` để trò chuyện thời gian thực. Bổ sung tính năng tự động tải lịch sử chat cũ khi mở màn hình.
- **Thanh Điều Hướng (Custom Bottom Nav Bar)**: Tạo widget `CustomBottomNavBar` sử dụng hiệu ứng Glassmorphism (kính mờ) và đổ bóng phát sáng (Glow shadow) cho các icon được chọn.
- **Màn hình Trang chủ (Home Screen)**: Xây dựng UI `home_screen.dart` theo chuẩn Premium Dark Theme kết hợp Mesh Gradient. Thiết kế các "Thẻ người dùng ẩn danh" với Avatar AI có hiệu ứng nhịp thở (Breathing light) và biểu đồ sóng tần số cảm xúc được mã hóa màu.
- **Kiến trúc Điều hướng Chuyên nghiệp**:
  - Xây dựng `main_screen.dart` làm màn hình khung (Dashboard) chính, sử dụng `IndexedStack` để quản lý các tab (Home, Chat, Matches, Profile) một cách mượt mà và giữ nguyên trạng thái.
  - Tạo `profile_screen.dart` với giao diện Glassmorphism đồng bộ và tích hợp tính năng Đăng xuất.
- **Tối ưu Luồng Trải nghiệm Người dùng (UX Flow)**:
  - Xóa bỏ màn hình `WelcomeScreen` tĩnh.
  - Thay thế bằng `OnboardingModal` (Modal Popup) hiển thị trên `HomeScreen` cho người dùng lần đầu, tạo lời mời gọi hành động mạnh mẽ.
  - Tạo widget `FloatingAiBubble` (Bong bóng AI nổi) để khuyến khích tương tác sau khi người dùng đã bắt đầu trò chuyện.
- **Refactor Giao diện (UI Overhaul)**:
  - Thay đổi toàn bộ tone màu chủ đạo của ứng dụng từ Đỏ/Hồng sang **Xanh dương đậm và Trắng**, mang lại cảm giác công nghệ, sâu lắng và hiện đại.
  - Nâng cấp `ToastUtil` với hiệu ứng trượt từ trên xuống kết hợp mờ dần (FadeIn), tăng tính tinh tế.

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

## 📅 Ngày: 01/04/2026

### 🎯 Trọng tâm hôm nay: Đánh bóng UI/UX (Polishing) và Tối ưu trải nghiệm tương tác (Micro-interactions)

#### 1. Frontend (Flutter)

- **Thanh điều hướng (CustomBottomNavBar)**:
  - Thiết kế lại theo dạng Floating Capsule (viên thuốc nổi), đổ bóng hiện đại.
  - Thêm hiệu ứng Highlight Pill (vòng tròn sáng) trượt mượt mà theo tỷ lệ màn hình chính xác 100%.
  - Hỗ trợ hiển thị ảnh Active Icons (giữ nguyên màu gốc khi chọn) và khắc phục triệt để lỗi đè màu (color override).
  - Tích hợp logic load Avatar thật của người dùng từ `FlutterSecureStorage` kèm theo hệ thống Fallback an toàn (chống crash app khi lỗi mạng/mất ảnh).
- **Bong bóng AI (FloatingAiBubble)**:
  - Nâng cấp trải nghiệm kéo thả mượt mà (smooth 60fps) dựa trên tọa độ tuyệt đối (`globalPosition`), không còn độ trễ.
  - Bổ sung hiệu ứng vật lý: Tự động "hít" (snap) về 2 mép màn hình khi thả tay ra (hiệu ứng nảy easeOutBack).
  - Thêm tính năng kéo xuống đáy để xóa (Close Target "X") y hệt chat head của Messenger.
  - Tích hợp `SharedPreferences` để lưu lại tọa độ của bong bóng, giữ nguyên vị trí ngay cả khi tắt app mở lại.
- **Đồng bộ hóa Dữ liệu Đăng nhập**:
  - Cập nhật `login_screen.dart` để lấy và lưu trữ `avatarUrl` (từ Google hoặc Backend) xuống bộ nhớ bảo mật.
  - Sửa lỗi Layer (Z-index) trong `main_screen.dart` giúp Bong bóng AI luôn nổi lên trên cùng, không bị thanh Navbar che khuất.
- **Màn hình Cá nhân (ProfileScreen)**:
  - Chuyển đổi thành `StatefulWidget` để tự động tải và hiển thị `avatarUrl` thực tế từ `FlutterSecureStorage`.
  - Thiết kế giao diện Glassmorphism với hiệu ứng viền sáng và đổ bóng (glow) cho Avatar, kết hợp fallback an toàn chống crash.
  - Cấu trúc lại danh sách cài đặt thành các khối thẻ (Card Menu) bo góc tròn mềm mại.
  - Cải tiến nút Đăng xuất (Logout) với viền đỏ nổi bật và logic xóa toàn bộ session mượt mà.
- **Trải nghiệm Chat (ChatInputBar & Morphing UI)**:
  - Tách riêng `ChatInputBar` thành widget độc lập. Thiết kế dạng viên thuốc nổi (floating pill) với nút '+' xoay 45 độ (`AnimatedRotation`).
  - Thêm hiệu ứng Morphing bằng `AnimatedSwitcher` tại `main_screen.dart` để hoán đổi mượt mà (Slide & Fade) giữa Bottom Nav và Chat Input khi người dùng chuyển tab.
  - Thiết kế Custom Modal Popup bật lên từ nút '+' sử dụng hiệu ứng vật lý lò xo (Spring Physics) kết hợp lớp nền kính mờ tập trung (`BackdropFilter`).
  - Cải tiến UI Modal Popup với các icon chức năng (Home, Matches, Profile) được gán màu sắc đặc trưng (Xanh dương, Hồng, Tím) kèm nền mờ ánh màu đồng bộ cực kỳ bắt mắt.
  - Tích hợp logic tự động chuyển đổi nút Mic và Send thông minh bằng `ValueListenableBuilder` và `ScaleTransition` dựa trên trạng thái nhập liệu.

---

## 📅 Ngày: 02/04/2026

### 🎯 Trọng tâm hôm nay: Thuật toán Matchmaking, AI JSON Enforcement & Data Visualization

#### 1. Backend (NestJS)

- **Thuật toán Matchmaking (Toán học)**: Xây dựng thành công `MatchmakingService` kết nối trực tiếp MongoDB, sử dụng 2 công thức: **Khoảng cách Euclidean** (tương đồng tính cách) và **Ma trận bù trừ cảm xúc** (Complementary Matrix) với tỷ lệ trọng số 40-60.
- **AI JSON Enforcement**: Nâng cấp `GeminiService` bắt buộc trả về định dạng `application/json` chứa `reply`, `latestEmotion`, `detected_emotions`, và `detected_personality`.
- **Thuật toán làm mượt dữ liệu (EMA)**: Áp dụng Exponential Moving Average trong `UsersService.updateUserTraits` để cập nhật từ từ vector cảm xúc (80/20) và tính cách (90/10) của người dùng mỗi khi chat với AI, đảm bảo dữ liệu không bị nhiễu do một vài cảm xúc nhất thời.
- **API Profile**: Bổ sung endpoint `GET /users/:id/profile` để cung cấp dữ liệu phân tích sâu (Deep Analytics) về người dùng cho Frontend.

#### 2. Frontend (Flutter)

- **Radar Chart (Biểu đồ Tần số)**: Tích hợp thư viện `fl_chart` vào `ProfileScreen` để trực quan hóa "Tần số cảm xúc" (Stress, Lonely, Sadness, Calm, Warmth, Happy) bằng biểu đồ Radar đa giác, tự động lấy và render dữ liệu thực tế từ API Backend.
- **Giao diện MatchesScreen**: Thiết kế UI hiện đại cho màn hình "Định mệnh của bạn" với nền Dark Mesh Gradient (Glow đỏ/hồng), Card Glassmorphism, Avatar viền sáng và huy hiệu hiển thị % Tương hợp.
- **Hiệu ứng Micro-interaction**: Thêm hiệu ứng vật lý nảy (Bounce/Scale) khi nhấn giữ (`onTapDown`, `onTapUp`) vào các nút điều hướng chức năng bên trong Custom Modal Popup.

---

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [x] **Frontend**: Xây dựng màn hình chờ (Splash Screen) có logic auto-login.
- [x] **Frontend**: Xây dựng UI màn hình Welcome để chuẩn bị Onboarding.
- [x] **Frontend**: Thiết kế `chat_screen.dart` với khung chat tinh tế để bắt đầu nói chuyện với Faye AI.
- [x] **Backend**: Xây dựng `ChatModule` sử dụng WebSocket (Socket.IO hoặc ws) để phục vụ cho việc chat real-time giữa người dùng và AI.
- [x] **Frontend & Backend**: Liên kết Bottom Navigation Bar (điều hướng thực tế giữa các tab Home, Chat, Matches, Profile).
- [x] **Frontend**: Hoàn thiện UI/UX cho màn hình Profile (ProfileScreen).
- [x] **Backend**: Viết API GET trả về danh sách người dùng ẩn danh cho `HomeScreen` dựa trên thuật toán Matchmaking sơ bộ.
- [ ] **Frontend**: Kết nối API thực tế để lấy danh sách những người đã ghép đôi cho màn hình `MatchesScreen`.
- [ ] **Frontend**: Tích hợp tính năng Đa ngôn ngữ (i18n / Switch Language) sử dụng `easy_localization`.
