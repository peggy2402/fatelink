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

#### 3. Cập nhật thêm (Cuối ngày 02/04/2026)

- **Kết nối API Matches**: `MatchesScreen` đã được gọi API thực tế, tích hợp phân trang (Load More) với `ScrollController`, xử lý lỗi parse JSON an toàn và UI Hủy ghép đôi (Unmatch).
- **Đa ngôn ngữ (i18n)**: Cài đặt thành công `easy_localization`, bọc toàn bộ app, cho phép chuyển đổi ngôn ngữ Anh-Việt mượt mà tại `ProfileScreen`.
- **Match Chat & AI Assistant**: Tạo màn hình `MatchChatScreen` dành riêng cho việc chat với người được ghép đôi, tích hợp nút "Faye gợi ý mở lời" (AI Assistant) giúp người hướng nội dễ dàng bắt chuyện.
- **Fix Bug Gemini**: Sửa lỗi AI báo bận bằng cách chuyển đổi mảng History thành string nhúng trực tiếp vào prompt, đảm bảo định dạng JSON trả về luôn chuẩn xác.

---

## 📅 Ngày: 02/04/2026 (Cập nhật lần 3)

### 🎯 Trọng tâm: Nâng cấp Kiến trúc AI (Fallback Chain), Real-time Socket & Triển khai Fly.io

#### 1. Kiến trúc Hệ thống AI (Strategy Pattern & Fallback)

- **Refactor toàn diện AI Service**: Đổi tên `GeminiService` thành `AiService`, áp dụng mô hình thiết kế Strategy Pattern để quản lý linh hoạt nhiều nhà cung cấp AI.
- **Xây dựng AI Providers**:
  - `GeminiProvider`: Nâng cấp lên thư viện mới nhất `@google/genai`. Xử lý logic tự động hạ cấp model (fallback từ `gemini-2.0-flash` xuống `gemini-1.5-pro` hoặc `1.5-flash`) khi gặp lỗi 404 hoặc bị Rate Limit.
  - `OpenAiProvider`: Tích hợp ChatGPT (`gpt-4o-mini`) làm phương án dự phòng thứ nhất.
  - `MockAiProvider`: Chốt chặn cuối cùng (Last-resort fallback). Tự động trả về chuẩn JSON báo lỗi "quá tải" khi tất cả các API thực tế đều hết Quota (lỗi HTTP 429), giúp ứng dụng không bao giờ bị crash.
- **Cơ chế Timeout**: Áp dụng `Promise.race` để giới hạn thời gian chờ (15s) cho mỗi Provider, tránh kẹt request gây treo server.
- **Dependency Injection**: Cấu hình `useFactory` trong `AiModule` để thiết lập chuỗi ưu tiên tự động: Gemini -> OpenAI -> MockAI.

#### 2. Tối ưu Real-time WebSocket (NestJS & Flutter)

- **Quản lý Trạng thái Global**: Tạo `ChatProvider` trên dự án Flutter, sử dụng `ChangeNotifier` để quản lý tập trung trạng thái Online và Typing.
- **Tối ưu Broadcast Backend**: Nâng cấp `ChatGateway` tự động phát sự kiện `userStatusChanged` tới toàn bộ client ngay khi có người connect/disconnect thay vì để client phải polling. Bổ sung sự kiện `checkUsersStatus` để tra cứu hàng loạt giúp tối ưu băng thông.
- **Trải nghiệm Gõ phím (Typing Indicator)**:
  - Tích hợp package `flutter_spinkit` tạo hiệu ứng 3 chấm nảy lên nảy xuống mượt mà.
  - Bắt sự kiện vòng đời `dispose()` trong `MatchChatScreen` để tự động gửi tín hiệu "ngừng gõ" (isTyping: false) khi thoát màn hình.
- **Quản lý Service**: Sử dụng `ProxyProvider` trong Flutter để khởi tạo và cung cấp `SocketService` ở phạm vi toàn cục.

#### 3. Bug Fixes & Deployment (Fly.io)

- **Khắc phục lỗi TypeScript**:
  - Xử lý triệt để cảnh báo kiểu `unknown` trong các khối `catch` bằng cách ép kiểu `error: any` tại `chat.gateway.ts` và `matchmaking.service.ts`.
  - Sửa lỗi import bằng đường dẫn tuyệt đối (đổi từ `src/...` sang `../...`) để tương thích với `"moduleResolution": "nodenext"` khi chạy lệnh `npm run build` trên cloud.
- **CI/CD Actions**: Khắc phục lỗi `invalid token: all tokens missing third-party discharge tokens` trên GitHub Actions bằng cách thay thế Personal Token thành Deploy Token chuyên dụng của Fly.io (`flyctl tokens create deploy`).

#### 4. Tích hợp AI Cục bộ (Local LLM - Llama 3)

- **Thử nghiệm & Chuyển đổi thư viện**: Khởi đầu với `@llama-node` nhưng gặp lỗi type definition (do thư viện cũ/ngừng bảo trì). Đã chuyển sang `node-llama-cpp` ổn định và hỗ trợ TypeScript tối ưu hơn.
- **Xây dựng LlamaProvider**: Tạo provider nạp trực tiếp model lượng tử hóa (`.gguf`) vào RAM thông qua `LlamaChatSession`, cho phép AI chạy hoàn toàn offline.
- **Cấu hình Model chuẩn**: Chốt phương án dùng `Meta-Llama-3-8B-Instruct.Q4_K_M.gguf` (bản Instruct, chuẩn Q4) thay vì bản Base/Q2 để đảm bảo AI đủ thông minh và tuân thủ định dạng JSON đầu ra phục vụ cho app Flutter.
- **Tối ưu Fallback Chain**: Cập nhật `AiModule`, đưa Llama vào chuỗi dự phòng khép kín: `Gemini` -> `LlamaLocal` -> `OpenAI` -> `MockAI`.
- **Lưu ý Hạ tầng (OOM)**: Chạy Local LLM yêu cầu cấu hình máy RAM 8GB+. Nếu deploy lên các host Free-tier (như Fly.io/Railway với 256MB RAM) sẽ bị crash (Out of Memory). Giải pháp thay thế là sử dụng Groq API để gọi Llama 3 miễn phí & siêu tốc.

---

## 📅 Ngày: 03/04/2026

### 🎯 Trọng tâm: Admin Dashboard (Quản trị hệ thống), Dynamic AI Models, HuggingFace & Push Notification

#### 1. Hạ tầng & Triển khai (Fly.io & Docker)

- **Khắc phục lỗi Build**: Nâng cấp base image từ `node:18-alpine` sang `node:20-slim` để hỗ trợ biên dịch C++ (`node-llama-cpp`) và tương thích hoàn toàn với các package yêu cầu Node >= 20.
- **Tối ưu RAM Production**: Cấu hình tự động vô hiệu hóa (`disable`) Local Llama khi `NODE_ENV=production` để ngăn chặn lỗi sập server (OOM) trên VPS 512MB RAM của Fly.io.
- **Xác minh Fallback Chain**: Hệ thống dự phòng AI đã hoạt động hoàn hảo 100% trong thực tế (Tự động bypass LlamaLocal -> xử lý lỗi Model Decommissioned của Groq -> Fallback thành công xuống MockAI).

#### 2. Xây dựng Admin Dashboard "All-in-One" (Trình duyệt Web)

- **Frontend Web (TailwindCSS)**: Tạo giao diện quản trị siêu mượt trực tiếp bằng HTML/JS thuần trong thư mục `public` của NestJS, được phục vụ qua `ServeStaticModule`.
- **Hệ thống API Quản trị (NestJS)**:
  - **Bảo mật**: Triển khai `JwtModule` và `AdminGuard` để tạo token JWT và bảo vệ toàn bộ API `/admin/*`. Tài khoản mặc định đọc từ biến môi trường `.env`.
  - **Quản lý Users**: Thêm chức năng xem danh sách, Tìm kiếm (Search), Lọc (Filter) trạng thái và Khóa/Mở khóa (Ban/Unban) tài khoản người dùng.
  - **Quản lý Cấu hình (SystemConfig)**: Cho phép thay đổi linh hoạt System Prompt và "Bơm kiến thức" (Additional Knowledge) như sách tâm lý học hành vi trực tiếp vào não AI.
  - **Quản lý Models AI (CRUD)**: Không còn hardcode! Xây dựng bảng `AiModels` cho phép Thêm/Sửa/Xóa các provider AI. Tích hợp tính năng Kéo & Thả (Drag & Drop) Native HTML5 để thay đổi độ ưu tiên của model.
  - **Trạng thái Model (Ping Check)**: Chức năng gửi request đồng loạt để đo độ trễ (Ping) và kiểm tra sức khỏe (Online/Offline) của toàn bộ các Provider trong chuỗi Fallback.
  - **Test Chat AI**: Khung chat giả lập ngay trên Dashboard hiển thị raw JSON, giúp Admin dễ dàng thử nghiệm và tinh chỉnh Prompt đầu ra.

#### 3. Nâng cấp Hệ sinh thái AI (AiModule)

- **In-memory Caching**: Tối ưu hóa việc gọi Database bằng cách lưu Cache cấu hình Prompt trong 60 giây.
- **Dynamic AI Router**: `AiService` tự động đọc danh sách Model đang bật (`isEnabled: true`) từ Database, sắp xếp theo ưu tiên và linh hoạt điều hướng prompt.
- **Tích hợp HuggingFaceProvider**:
  - Thêm nhà cung cấp mới sử dụng chuẩn OpenAI API (`router.huggingface.co/v1/chat/completions`).
  - Cấu hình thành công model **Qwen/Qwen2.5-7B-Instruct** (Nhẹ, khởi động nhanh, tiếng Việt xuất sắc) thay thế cho các model quá nặng. Tăng timeout lên 60s để khắc phục lỗi Cold Start.

#### 4. Push Notification (Firebase Cloud Messaging - FCM)

- **Backend (NestJS)**:
  - Cài đặt `firebase-admin`, xử lý chuẩn xác cấu trúc chứng chỉ PEM (`\n`) cho `FIREBASE_PRIVATE_KEY` trên môi trường Linux.
  - Cập nhật `UsersService` lưu trữ `fcmToken` vào MongoDB.
  - Tạo `NotificationService` để dễ dàng gọi hàm gửi thông báo từ bất kỳ module nào.
- **Frontend (Flutter)**:
  - Tích hợp `firebase_messaging` và xin quyền thông báo thành công.
  - Quản lý vòng đời thông báo:
    - **Foreground**: Hiện thông báo thả xuống mượt mà bằng `fluttertoast`.
    - **Background / Terminated**: Sử dụng `GlobalKey<NavigatorState>` để bắt sự kiện nhấp vào thông báo và tự động điều hướng người dùng thẳng vào `MatchChatScreen` với đúng `partnerId`.

#### 5. Cải thiện UX phòng Chat (Faye AI)

- **AI Chủ động mở lời**: Sửa logic tại `ChatScreen`, khi người dùng mới vào phòng chat (chưa có lịch sử), Faye sẽ tự động gửi câu hỏi đầy EQ: _"Hôm nay tâm trạng của bạn đang như thế nào? 🍂"_.
- **Emotion Action Chips**: Thay vì bắt người dùng tự gõ, ứng dụng sẽ render một loạt các nút bấm cảm xúc (Bình yên, Áp lực, Cô đơn...) để người dùng chọn nhanh, tăng tỷ lệ tương tác (Conversion Rate) cho Onboarding Phase 1.

#### 6. Nâng cấp Bảng Điều khiển (Admin Dashboard) & Matchmaking Phase 2

- **Tối ưu hiển thị AI Models (Quan hệ 1-N)**: Cập nhật logic `AiService` và Dashboard để gom nhóm (Group By) chính xác nhiều Model thuộc cùng 1 Provider. Khắc phục triệt để lỗi hiển thị `N/A` và "Chưa xác định" khi test ping trạng thái.
- **Phân trang & Tìm kiếm (Pagination & Filtering)**: Tích hợp thuật toán phân trang và lọc dữ liệu cực mượt cho cả bảng Users và AI Models trực tiếp bằng JavaScript ở Frontend.
- **Xuất file Logs Server**: Cấu hình Node.js `fs` ghi log hệ thống theo thời gian thực xuống file `admin_logs.txt` và xây dựng API `GET /admin/logs/download` cho phép tải về máy.
- **Bảo mật & Fix lỗi Typescript**:
  - Kích hoạt CORS bảo mật trong `main.ts` chỉ cho phép các domain được cấp quyền.
  - Sửa lỗi Dependency Injection (`JwtModule`) trong `UsersModule`.
  - Khắc phục xung đột kiểu dữ liệu decorator bằng `import type { Response }`.
- **Giao diện chuyển pha Matchmaking (Flutter)**: Bắt thành công sự kiện `matchReady` qua Socket.IO và hiển thị Popup "Đã thấu hiểu tâm hồn" rực rỡ, tạo điểm chạm mượt mà để chuyển hướng người dùng sang `MatchesScreen`.

---

## 📅 Ngày: 03/04/2026 (Cập nhật lần 4)

### 🎯 Trọng tâm: Tinh chỉnh Admin Dashboard (UI/UX) & Khắc phục lỗi AI Provider

#### 1. Frontend (Admin Dashboard - HTML/JS)

- **Nâng cấp Bảng AI Models**: Tách biệt rõ ràng cột "Provider" và "Model ID". Bổ sung tính năng Lọc (Filter) bằng Dropdown theo từng nhà cung cấp (Gemini, OpenAI, HuggingFace, LlamaLocal...).
- **Tối ưu Mobile (Responsive)**:
  - Áp dụng thiết kế Off-canvas Sidebar với nút Hamburger và màng che mờ (Overlay) cho thiết bị di động.
  - Chuyển đổi linh hoạt các bảng dữ liệu (Table) thành dạng danh sách thẻ (Card List) khi xem trên màn hình nhỏ, các nút thao tác được mở rộng để dễ bấm chạm.
- **Biểu đồ Thống kê (Data Visualization)**: Tích hợp thư viện `Chart.js` để vẽ biểu đồ tròn (Doughnut Chart) hiển thị trực quan tỷ lệ phân bổ trạng thái cảm xúc của toàn bộ người dùng trong hệ thống.

#### 2. Backend (NestJS & AI Providers)

- **Khắc phục lỗi Gemini 404**: Cập nhật `GeminiProvider`, thay đổi model mặc định thành các phiên bản định danh (versioned name) như `gemini-2.0-flash-exp` và cấu hình logic fallback an toàn về `gemini-1.5-pro-002` để triệt tiêu hoàn toàn lỗi Not Found từ API của Google.

---

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [x] **Frontend**: Xây dựng màn hình chờ (Splash Screen) có logic auto-login.
- [x] **Frontend**: Xây dựng UI màn hình Welcome để chuẩn bị Onboarding.
- [x] **Frontend**: Thiết kế `chat_screen.dart` với khung chat tinh tế để bắt đầu nói chuyện với Faye AI.
- [x] **Backend**: Xây dựng `ChatModule` sử dụng WebSocket (Socket.IO hoặc ws) để phục vụ cho việc chat real-time giữa người dùng và AI.
- [x] **Frontend & Backend**: Liên kết Bottom Navigation Bar (điều hướng thực tế giữa các tab Home, Chat, Matches, Profile).
- [x] **Frontend**: Hoàn thiện UI/UX cho màn hình Profile (ProfileScreen).
- [x] **Backend**: Viết API GET trả về danh sách người dùng ẩn danh cho `HomeScreen` dựa trên thuật toán Matchmaking sơ bộ.
- [x] **Frontend**: Kết nối API thực tế để lấy danh sách những người đã ghép đôi cho màn hình `MatchesScreen`.
- [x] **Frontend**: Tích hợp tính năng Đa ngôn ngữ (i18n / Switch Language) sử dụng `easy_localization`.
- [x] **Backend & Frontend**: Viết API "Unmatch" trong NestJS và tích hợp thành công trên giao diện Flutter.
- [x] **Frontend**: Xây dựng UI chức năng Báo cáo người dùng (Report User) trong màn hình Match Chat.
- [x] **Frontend & Backend**: Tích hợp Firebase Cloud Messaging (FCM) để gửi Push Notification khi có tin nhắn mới (lúc app chạy nền).
- [x] **AI & Matchmaking**: Thiết kế luồng chuyển tiếp (Transition) từ Phase 1 (Onboarding) sang Phase 2 (Matchmaking) khi API trả về `is_ready_to_match: true`.

---

## 📅 Ngày: 06/04/2026

### 🎯 Trọng tâm: Tối ưu Hệ thống Network, Global Error Handling & Fix Bugs

#### 1. Frontend (Flutter)

- **Sửa lỗi Đăng nhập Google (ApiException: 10)**: Xử lý dứt điểm lỗi OAuth do thiếu mã SHA-1 của máy tính (debug keystore) trên Firebase, đảm bảo sử dụng chính xác loại "Web application" Client ID trên cấu hình code Flutter.
- **Tối ưu Network & Cấu hình môi trường**: Tạo file `utils/constants.dart` quản lý tập trung URL cấu hình cho toàn dự án. Đồng bộ hóa tiền tố `/api` cho tất cả các request HTTP REST để khắc phục triệt để lỗi 404 trả về trang HTML (FormatException).
- **Global API Wrapper**: Triển khai class `ApiService` (HTTP Wrapper) nhằm:
  - Tự động parse JSON cho mọi request.
  - Bắt lỗi HTTP tập trung (thay vì văng lỗi Exception lắt nhắt).
  - Tự động xóa token và chuyển hướng cưỡng chế về màn hình `LoginScreen` khi Token hết hạn hoặc không hợp lệ (Lỗi 401/403).
- **Trải nghiệm Chat (Auto-scroll)**: Cải thiện UI/UX màn hình chat bằng cách lệnh cho `ScrollController` tự động nhảy thẳng (jumpTo) hoặc cuộn mượt (animateTo) xuống vị trí dưới cùng (`maxScrollExtent`) khi tải xong lịch sử tin nhắn hoặc có tin nhắn mới tới, tránh việc danh sách bị kẹt ở trên cùng.

### 🚀 Việc cần làm tiếp theo (Next Steps):

- [ ] **Frontend**: Xây dựng UI màn hình `EditProfileScreen` chi tiết để hỗ trợ tính năng Update Profile (sử dụng ApiService.put).
- [ ] **Frontend**: Tích hợp cơ chế phân trang (Load more / Infinite scroll) cho danh sách người dùng trong `HomeScreen`.

---

## 📅 Ngày: 08/04/2026

### 🎯 Trọng tâm: Hoàn thiện Frontend (UI/UX), Phân trang, Đa ngôn ngữ & Xử lý Socket

#### 1. Frontend (Flutter) - Màn hình Ghép đôi (MatchesScreen)
- **Sửa lỗi Compile-time (`const`)**: Khắc phục dứt điểm lỗi `Method invocation is not a constant expression` liên quan đến hàm `.tr()` của `easy_localization` bằng cách cấu trúc lại các widget.
- **Phân trang (Infinite Scroll / Load More)**: Tích hợp `ScrollController` tự động gọi API lấy thêm danh sách người dùng khi cuộn gần cuối (cách 200px). Xử lý an toàn các trạng thái `_isLoadingMore` và `_hasMore` để tránh spam API.
- **Chức năng Hủy ghép đôi**: Thiết kế Dialog xác nhận "Hủy ghép đôi" (Unmatch). Cập nhật mượt mà UI bằng `_matches.removeWhere()` và hiển thị `SnackBar` thông báo thay vì phải chờ reload toàn bộ trang.
- **Điều hướng an toàn**: Bổ sung truyền biến `partnerId` và `partnerName` sang màn hình `MatchChatScreen`. Tự động gọi lại API làm mới danh sách nếu người dùng thực hiện Unmatch từ trong phòng chat.

#### 2. Frontend (Flutter) - Trải nghiệm Chat (ChatScreen)
- **Gợi ý Cảm xúc (Emotion Action Chips)**: Bổ sung các nút thẻ cảm xúc nhanh (Bình yên 🍃, Áp lực 🌪️, Cô đơn 🌧️...) cho câu chào mở màn của AI, giúp người dùng mới dễ dàng bắt đầu câu chuyện.
- **Chuyển pha Matchmaking (Phase 2 Transition)**: Bắt thành công sự kiện `matchReady` qua Socket.IO. Hiển thị `AlertDialog` "✨ Đã thấu hiểu tâm hồn" rực rỡ và cho phép điều hướng thẳng tới tab Định mệnh.
- **Bảo vệ Timeout (15s)**: Thêm cơ chế tự động ngắt trạng thái gõ phím (`_isTyping`) và hiển thị lỗi mạng nếu AI / Server không phản hồi trong vòng 15 giây.

#### 3. Frontend (Flutter) - Cá nhân hóa & Dashboard (Profile & MainScreen)
- **Biểu đồ Radar (fl_chart)**: Tích hợp thư viện biểu đồ vẽ Radar Chart hiển thị "Tần số cảm xúc" của người dùng trực quan ngay trên `ProfileScreen`.
- **Đa ngôn ngữ (i18n)**: Gắn hành động chuyển đổi mượt mà giữa Tiếng Việt và Tiếng Anh sử dụng `context.setLocale()` cho nút cài đặt ngôn ngữ.
- **Custom Modal Popup**: Áp dụng hiệu ứng vật lý lò xo (Spring Physics - `Curves.elasticOut`) cực mượt cho Popup nổi lên từ phím `+` giữa màn hình. Cải thiện lớp nền che phủ (`BackdropFilter`).
- **Thông báo thông minh**: Bong bóng AI (`FloatingAiBubble`) đã liên kết thành công với biến `_hasUnreadMessages`, hiển thị chấm đỏ (red dot) cảnh báo nếu có tin nhắn mới tới mà người dùng đang không ở trong phòng chat.

#### 4. Frontend (Flutter) - Đăng nhập & Log Hệ thống (LoginScreen)
- **Quản lý Log cục bộ**: Xây dựng hàm `_saveLogToFile` lưu lại các sự kiện lỗi ra file `.txt` trên điện thoại, hỗ trợ tốt cho việc debug các thiết bị thực tế không cắm cáp.
- **Điều khoản & Chính sách**: Thêm checkbox bắt buộc đồng ý các điều khoản dịch vụ trước khi đăng nhập. Sử dụng `TextSpan` kết hợp `TapGestureRecognizer` mở trình duyệt web an toàn.
- **Animation Nút bấm**: Bổ sung hiệu ứng nảy (Bounce) sinh động liên tục cho nút Đăng nhập Google, kích thích tương tác của người dùng.
