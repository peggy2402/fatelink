# BỘ PROMPT CHUẨN MVP CHO ỨNG DỤNG "SOULCONNECT - AI SOCIAL"

---

## 1. Prompt Lập trình & Nâng cấp Giao diện Mobile (System/User Prompt cho AI Code Assistant)

> **Mục đích:** Dùng khi bạn muốn yêu cầu AI viết lại toàn bộ mã nguồn HTML/TailwindCSS/JS cho ứng dụng mobile.

```text
Hãy thiết kế một giao diện Mobile UI Single-Page Application (SPA) chuẩn MVP cho ứng dụng mạng xã hội AI mang tên "SoulConnect" - Nền tảng kết nối cảm xúc & tần số tâm hồn.

Yêu cầu kỹ thuật & UI/UX:
- Công nghệ: HTML5, Tailwind CSS (CDN), FontAwesome 6, font chữ Plus Jakarta Sans hoặc Inter.
- Khung hiển thị: Thiết kế chuẩn di động iOS/Android (390px x 844px), có tùy chọn Phóng to/Thu nhỏ khung hình và Toggle Chế độ Sáng/Tối (Light/Dark Mode).
- Màu sắc chủ đạo: Gradient Tím - Hồng - Xanh Neon (Magenta Pink #ec4899, Indigo #6366f1, Dark Slate #0f172a), phong cách Glassmorphism hiện đại.

Các thành phần chính cần xuất hiện trên trang chủ:
1. Header:
   - Avatar người dùng với viền phát sáng, tên người dùng, badge "PRO".
   - Bộ nút thao tác nhanh: Tìm kiếm, Quét mã QR, Thông báo (có chấm đỏ) và Cài đặt.
2. Hero Banner "Trợ lý AI Faye":
   - Nổi bật với hiệu ứng Glassmorphism & Gradient sinh động.
   - Nội dung giới thiệu ngắn gọn, nút CTA "Trải nghiệm ngay" dẫn trực tiếp vào khung Chat bot.
3. Thanh trạng thái "Đang trực tuyến" (Online Avatars):
   - Danh sách Avatar cuộn ngang, viền LED/Pulse nhịp đập năng lượng.
   - Nút đầu tiên cho phép người dùng đăng "Khoảnh khắc/Story tâm trạng".
4. Danh sách "Kết nối tâm hồn" (Soul Match Feed):
   - Bộ lọc nhanh (Filter Chips): Tất cả, Cô đơn, Phấn khích, Deep talk, Cùng vị trí.
   - Các Card người dùng tương thích: Tỉ lệ Match score % dạng Gradient nổi bật, hiển thị tần số cảm xúc (#NhạcIndie, #Startup...), khoảng cách địa lý và các nút hành động thả tim / gửi tin nhắn nhanh.
5. Bottom Navigation Bar & Nút Radar Trung tâm:
   - Thanh điều hướng 4 tab (Trang chủ, Khám phá, Trò chuyện, Tài khoản).
   - Ở giữa là Nút Radar Heart nổi dạng hạt nhân (Floating Pulse Heart Button), bấm vào mở Modal quét Radar tìm kiếm tâm hồn xung quanh.
6. Tính năng tương tác đi kèm:
   - Trợ lý AI Faye Widget nổi ở góc phải màn hình.
   - Các Modal tương tác tĩnh: Radar Scanner, Khung Chat với Trợ lý AI Faye, và hệ thống Thông báo Toast dịu nhẹ.
```

---

## 2. Prompt Tạo Hình Ảnh Concept UI (Dành cho Midjourney v6 / DALL-E 3)

> **Mục đích:** Dùng để tạo hình ảnh mockup UI sắc nét, chuyên nghiệp làm ảnh quảng cáo, landing page hoặc slide gọi vốn.

### Prompt Midjourney v6 (Chế độ UI/UX Design):
```text
Clean mobile app UI design for an AI-powered social emotional connection app named SoulConnect, modern iOS screen mockup, vibrant glassmorphism aesthetic, sleek gradient palette of neon magenta, soft indigo, and deep dark violet background. Top section featuring user profile header with QR code icon, glowing hero banner for AI assistant 'Faye', horizontal avatar story circles with status rings, feed of user match cards with glowing percentage badges (92% Match), floating neon heart button at bottom bar, sleek dark mode UI, smooth typography, Figma showcase style, high resolution, 8k --ar 9:16 --v 6.0
```

### Prompt DALL-E 3:
```text
A high-quality 3D render UI mockup of a modern smartphone displaying a mobile app interface called 'SoulConnect'. The screen features a dark-mode theme with vibrant glassmorphism effects, neon pink and purple gradients. Key elements include a top bar with user profile and action icons, a hero banner showcasing an AI assistant named Faye, a horizontal row of online user avatars with glowing green status dots, match cards displaying soul compatibility scores like '85% Match', and a glowing floating heart button on the bottom navigation bar. Premium design studio quality.
```

---

## 3. Prompt Tóm tắt Dự án & Tính năng MVP (Dành cho Slide Pitch Deck / PRD)

> **Mục đích:** Dùng để tạo bài thuyết trình sản phẩm, mô tả dự án cho lập trình viên hoặc đối tác.

```text
Hãy viết bản tóm tắt sản phẩm (Product Brief) cho MVP ứng dụng "SoulConnect":

- Tên sản phẩm: SoulConnect - AI-Powered Emotional Social Network.
- Tầm nhìn: Kết nối con người dựa trên tần số cảm xúc và năng lượng tâm trạng thay vì chỉ dựa trên hình ảnh ngoại hình.
- Giá trị cốt lõi:
  1. AI Soul Matching: Phân tích tâm trạng và đề xuất người nói chuyện phù hợp tức thì theo tỉ lệ % Match.
  2. Trợ lý Faye AI: Bạn đồng hành lắng nghe, giải tỏa cảm xúc 24/7 và gợi ý chủ đề trò chuyện.
  3. Radar Tâm hồn: Tính năng quét vị trí thực thời gian thực để tìm các tâm hồn cùng tần số xung quanh.
- Đối tượng mục tiêu: Gen Z, Millennials, những người tìm kiếm các cuộc trò chuyện sâu sắc (Deep talk) hoặc giải tỏa nỗi cô đơn.
```