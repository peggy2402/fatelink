# BỘ PROMPT CHUẨN MVP - MÀN HÌNH ĐĂNG NHẬP "FATELINK"

---

## 1. Prompt Lập trình & Nâng cấp Giao diện Login (System/User Prompt cho AI Code Assistant)

> **Mục đích:** Dùng khi bạn muốn yêu cầu AI viết mã nguồn HTML5, Tailwind CSS và JavaScript cho trang đăng nhập/đăng ký di động của ứng dụng FateLink.

```text
Hãy thiết kế và nâng cấp giao diện Màn hình Đăng nhập (Mobile Login UI) chuẩn MVP cho ứng dụng mạng xã hội kết nối cảm xúc mang tên "FateLink".

Yêu cầu kỹ thuật & Phong cách UI/UX:
- Công nghệ: HTML5, Tailwind CSS (CDN), FontAwesome 6 Icons, Font chữ Plus Jakarta Sans / Inter.
- Khung hiển thị: Mobile Screen View iOS/Android (390px x 844px), có nút chuyển đổi Chế độ Sáng/Tối (Light/Dark Mode) và tùy chọn Phóng to/Thu nhỏ khung hình.
- Tông màu chủ đạo: Hồng neon (Rose/Pink gradient #f43f5e, #fb7185, #a855f7), phong cách Glassmorphism dịu nhẹ, lãng mạn nhưng hiện đại.

Các thành phần chính cần có trên giao diện Login:
1. Top Bar & Hỗ trợ:
   - Thanh trạng thái iOS mockup (Thời gian, Pin, Wifi).
   - Nút "Hỗ trợ" (Support Icon) ở góc trên bên phải mở Modal hỗ trợ trực tiếp/Hotline.
2. Header Thương hiệu (Branding Header):
   - Logo Trái tim 3D phát sáng nhịp đập (Glowing Pulse Heart Icon) với badge "PRO".
   - Tiêu đề thương hiệu "FateLink" với Gradient màu tím-hồng bắt mắt.
   - Dòng Slogan: "Đăng nhập để tiếp tục kết nối tần số trái tim".
3. Thanh chuyển đổi chế độ Auth (Tab Switcher):
   - Chuyển đổi linh hoạt giữa 2 tab: [Đăng nhập] và [Tạo tài khoản mới].
4. Các phương thức đăng nhập chính:
   - Nút CTA chính: "Tiếp tục với Google" tích hợp logo Google 4 màu chuẩn thương hiệu.
   - Hàng biểu tượng Đăng nhập nhanh qua Mạng xã hội: Facebook, TikTok, Zalo và Số điện thoại (SMS OTP).
   - Khung Đăng nhập Email dạng Accordion (mở rộng/thu gọn): nhập Email + Mật khẩu + Quên mật khẩu + Xem/Ẩn mật khẩu.
   - Thẻ tính năng "Magic Link": Đăng nhập 1 lần không cần mật khẩu gửi thẳng qua Email.
5. Modal & Tương tác nâng cao:
   - Modal nhập SĐT nhận mã OTP xác thực qua SMS.
   - Modal xác nhận gửi Magic Link qua Email.
   - Modal Trung tâm Hỗ trợ Khách hàng 24/7.
   - Hệ thống thông báo Toast dịu nhẹ khi thao tác thành công.
```

---

## 2. Prompt Tạo Hình Ảnh Concept UI Login (Midjourney v6 / DALL-E 3)

> **Mục đích:** Dùng để xuất hình ảnh render UI 3D sắc nét cho slide gọi vốn, thiết kế banner tiếp thị hoặc đăng bài giới thiệu ứng dụng.

### Prompt Midjourney v6:
```text
Sleek mobile app login screen UI design for an emotional social app named FateLink, clean iOS smartphone mockup, modern glassmorphism style, vibrant rose pink and soft purple gradient palette, glowing 3D gradient heart icon at top, prominent "Continue with Google" button, row of clean social login icons for Facebook, TikTok, Zalo and Phone, magic link passwordless option card, soft wave graphic at bottom, dark mode and light mode option, Figma showcase style, 8k resolution, ultra detailed --ar 9:16 --v 6.0
```

### Prompt DALL-E 3:
```text
A professional 3D render UI design mockup of a smartphone presenting the login screen for an app called 'FateLink'. The design features a romantic glassmorphism aesthetic with soft pink, magenta, and dark slate tones. At the top center, a glowing gradient heart logo with a PRO badge. Below it are streamlined login options including Google OAuth button, social media icons, an expandable email password card, a 'Magic Link' single-click login card, and a bottom decorative wave. Premium UI/UX portfolio style.
```

---

## 3. Prompt Tóm tắt Luồng Đăng nhập & Auth PRD (Dành cho Slide Pitch Deck / PRD)

> **Mục đích:** Dùng để tạo bản đặc tả luồng xác thực người dùng (Authentication Flow) cho tài liệu PRD hoặc giới thiệu kiến trúc MVP.

```text
Hãy viết bản mô tả luồng Xác thực người dùng (Authentication & Onboarding Flow) cho MVP ứng dụng "FateLink":

- Tên phân hệ: FateLink Smart Auth & Onboarding System.
- Mục tiêu UX: Tối ưu hóa tỉ lệ chuyển đổi (Conversion Rate), giảm ma sát khi đăng nhập, đảm bảo thời gian Onboarding dưới 15 giây.
- Phương thức đăng nhập được hỗ trợ:
  1. Social Auth (Google, Facebook, Zalo, TikTok): Đăng nhập 1-Click nhanh chóng.
  2. Phone SMS OTP: Xác thực an toàn qua mã OTP gửi về số điện thoại.
  3. Magic Link (Passwordless Login): Gửi liên kết truy cập an toàn trực tiếp vào Inbox Email.
  4. Email / Password Truyền thống: Dành cho người dùng ưa chuộng bảo mật tài khoản chuẩn.
- Luồng phân loại Tần số Cảm xúc (Emotion Onboarding): Sau khi đăng nhập thành công, hệ thống cho phép người dùng chọn nhanh tâm trạng (Deep talk, Phấn khích, Chill, Startup) để thuật toán Match gợi ý đúng đối tượng ngay từ đầu.
```