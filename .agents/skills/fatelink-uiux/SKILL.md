---
name: fatelink-uiux
description: Tiêu chuẩn thiết kế giao diện (UI/UX Design System), bảng màu Cosmic, chuẩn Typography BeVietnamPro, cơ chế hiển thị Avatar ẩn danh và hiệu ứng vi mô cho dự án FateLink. Kích hoạt khi thiết kế, refactor hoặc trau chuốt bất kỳ màn hình, widget, modal hay animation nào trong FateLink.
---

# FateLink UI/UX Design System & Experience Guidelines

> Bản quy chuẩn thiết kế trải nghiệm người dùng dành riêng cho ứng dụng **FateLink - Kết nối định mệnh & Tần số tâm hồn**.

---

## 1. Triết lý thiết kế (Design Philosophy)

FateLink không phải là ứng dụng hẹn hò quẹt thẻ thông thường; đây là nơi kết nối những tâm hồn đồng điệu dựa trên cảm xúc, sở thích và chiều sâu nội tâm.
- **Cosmic & Ethereal (Huyền ảo vũ trụ):** Gam màu neon kết hợp gradient sâu thẳm, tạo cảm giác bí ẩn, lãng mạn và cuốn hút.
- **Emotional Depth (Chiều sâu cảm xúc):** Tôn vinh các cuộc trò chuyện sâu lắng (#DeepTalk, #NhạcIndie, #ĐêmMuộn) trước khi lộ diện mạo thật.
- **Immersive & Clean (Tràn viền & Tinh tế):** Giao diện tiệm cận chuẩn mực của TikTok, Instagram và Linear: tối ưu tai thỏ/status bar, đổ bóng mềm, viền phát sáng nhẹ.

---

## 2. Bảng màu & Design Tokens (Color Palette)

Mọi thành phần giao diện phải sử dụng bảng màu quy chuẩn, không dùng mã màu thô:

| Tên Token | Mã Hex / Color | Ý nghĩa & Vị trí sử dụng |
| :--- | :--- | :--- |
| **Primary Indigo** | `#6366F1` / `Colors.indigo` | Màu chủ đạo hành động (CTA buttons, Active tabs, Radar center) |
| **Cosmic Violet** | `#8B5CF6` / `Colors.purple` | Ánh sáng tâm hồn, gradient chuyển tiếp |
| **Pulse Pink** | `#EC4899` / `Colors.pink` | Nhịp đập cảm xúc, thả tim, huy hiệu tình yêu |
| **Electric Cyan** | `#00E5FF` / `Colors.cyanAccent`| Năng lượng tương thích cao, ánh sáng radar |
| **Emerald Online** | `#10B981` / `Colors.emerald` | Trạng thái đang trực tuyến, tần số đang phát sóng |
| **Dark Cosmic BG** | `#0F172A` / `#0B0F19` | Nền Dark Mode huyền ảo |
| **Light Pearly BG** | `#F8FAFC` / `#FFFFFF` | Nền Light Mode thanh khiết, thoáng đãng |

### Gradient Signature Presets
1. **Fate Signature Gradient:**
   ```dart
   const LinearGradient(
     colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
   )
   ```
2. **Cosmic Tri-Color Glow:**
   ```dart
   const LinearGradient(
     colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF00E5FF)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
   )
   ```

---

## 3. Quy chuẩn Typography (`BeVietnamPro`)

Dự án đã tích hợp bộ font tiếng Việt cao cấp `BeVietnamPro` trong `pubspec.yaml`. Tuân thủ nghiêm ngặt cấp độ đậm nhạt:

- **Regular (w400):** Dùng cho nội dung bài viết, tin nhắn chat, bio, câu hỏi phụ.
- **Medium (w500):** Dùng cho các hashtag, thông tin metadata (khoảng cách km, thời gian).
- **SemiBold (w600):** **ĐÂY LÀ CHUẨN CHÍNH CHO TIÊU ĐỀ PHỤ & NÚT BẤM** (Tên người dùng, Button Text, Tab Label). *Tránh lạm dụng w700/w800 để không làm giao diện bị thô ráp, nặng nề.*
- **Bold (w700):** Chỉ dùng cho Tiêu đề màn hình (H1, H2), chỉ số tương thích % lớn.
- **Black (w900):** Dành riêng cho Logo FateLink hoặc số điểm kết nối nổi bật.
- **Text Scale Protection:** Mọi thanh ngang/chiều cao cố định phải tính toán kèm `MediaQuery.textScalerOf(context)` để người dùng chỉnh font to trên điện thoại không làm vỡ giao diện.

---

## 4. Chuẩn mực Avatar Ẩn Danh & Huy Hiệu (Anonymous Avatars)

Chế độ ẩn danh là linh hồn của FateLink. Mọi thành phần hiển thị danh tính đối phương phải tuân thủ:

1. **Hiển thị Avatar qua Helper:**
   Luôn sử dụng `AnonymousAvatarHelper.buildAvatar(...)` thay vì tự hiển thị `CircleAvatar` thô.
2. **Định danh ngẫu nhiên cố định (Deterministic Identity):**
   - Tên bí danh: `user.displayName` (tự động random `Soul#31241`, `Nova#8A49C`,... bằng seed `id.hashCode`).
   - Avatar 3D vũ trụ: Chọn tự động từ `assets/avatars/avatar_1.png` đến `avatar_6.png` theo seed `id.hashCode`.
   - **Tuyệt đối không dùng `Random()` không seed** để tránh avatar/tên bị giật nhảy khi cuộn màn hình hoặc hot reload.
3. **Quy tắc phân bổ Huy hiệu (Badges) để không chồng chéo:**
   - **Góc trên bên phải (`top-right`):** Dành riêng cho **Emoji Tần số đang phát / Cảm xúc** (☕, ✨, 🎧, 🌧️).
   - **Góc dưới bên phải (`bottom-right`):** Dành riêng cho **Huy hiệu Ổ khóa ẩn danh (🔒)** hoặc nút hành động (+ / Sửa).
4. **Mở khóa diện mạo:**
   Chỉ hiển thị diện mạo thật và ảnh thật khi: `canViewIdentity == true` (cả 2 cùng thả tim VÀ đối phương không bật Khóa diện mạo).

---

## 5. Tối ưu Tràn Viền & Status Bar (Edge-to-Edge Experience)

Lấy cảm hứng từ TikTok và Instagram, thanh trạng thái (giờ, pin, wifi) phải hòa hợp tuyệt đối với nền ứng dụng:

- **Khi có hình ảnh tràn viền / Banner:** Sử dụng gradient tối dần ở đỉnh màn hình (`LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent])`) để biểu tượng giờ/pin luôn đọc được rõ ràng.
- **Khi dùng AppBar cuộn:** Áp dụng `SliverAppBar(pinned: true)` kết hợp kính mờ `BackdropFilter` mỏng nhẹ:
  ```dart
  backgroundColor: Colors.white.withValues(alpha: 0.85),
  systemOverlayStyle: SystemUiOverlayStyle.dark, // Chữ đen trên nền sáng
  ```
- **Xử lý khoảng cách an toàn:** Không để text hoặc button quan trọng dính sát viền mép màn hình hoặc bị che bởi thanh điều hướng cử chỉ (Home bar).

---

## 6. Hiệu ứng vi mô & Tương tác (Micro-interactions)

- **Hiệu ứng Kính Mờ (Glassmorphism):** Dùng `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))` với viền mảnh `Border.all(color: Colors.white.withValues(alpha: 0.2))`.
- **Rung phản hồi xúc giác (Haptic Feedback):** Gọi `HapticFeedback.lightImpact()` khi người dùng thả tim, quẹt thẻ hoặc chạm vào radar để tăng cảm giác chân thực.
- **Trạng thái Trống & Đang tải:** Luôn có hiệu ứng Skeleton sóng sánh (Shimmer) thay vì chỉ một vòng quay tròn `CircularProgressIndicator` đơn điệu.

---

## 7. Quy chuẩn Nút Bấm CTA (Triệt tiêu tuyệt đối Vệt Vuông Mờ)

Khi thiết kế nút bấm gradient bo tròn (Pill / Rounded Button) có hiệu ứng chạm sóng nước (Ink splash):
- **LỖI NGHIÊM CẤM:** Không bao giờ đặt `boxShadow` bên trong `Ink(decoration: BoxDecoration(boxShadow: ...))` khi được bọc bởi `Material(color: Colors.transparent)`. Flutter sẽ vẽ bóng đổ lên canvas hình chữ nhật của `Material`, tạo ra vệt vuông mờ (rectangular ghost halo) đè sau nút bo tròn!
- **CHUẨN MỰC CHÍNH XÁC:**
  1. Đặt `BoxDecoration` (gồm `gradient`, `borderRadius`, và `boxShadow`) lên **`Container` ngoài cùng**.
  2. Bên trong `Container`, lồng `Material(color: Colors.transparent)` + `InkWell(borderRadius: ..., onTap: ...)` để chỉ xử lý hiệu ứng gợn sóng nước (ripple splash).
  ```dart
  Container(
    height: 50,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF6366F1)]),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFEC4899).withValues(alpha: 0.38),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => ...,
        child: const Center(child: ...),
      ),
    ),
  )
  ```

---

## 8. Quy chuẩn kiến trúc Web Portal & Clean Component Architecture

> Áp dụng cho toàn bộ phân hệ Web Admin Dashboard, Landing Pages và các trang chính sách/pháp lý trong thư mục `fatelink-be/public/`.

### A. Triệt tiêu tập tin nguyên khối (No Monolithic All-In-One Files)
- **LỖI CẤM:** Không bao giờ nhồi nhét toàn bộ logic nghiệp vụ (Auth, Config, User table, AI models, Socket chat, Logs) vào một file Javascript duy nhất (> 1,000 dòng như `admin.js` cũ) hoặc một file HTML duy nhất gom mọi tab.
- **NGUYÊN TẮC CLEAN ARCHITECTURE:**
  1. **Core Layer (`js/core/`):** Chứa các dịch vụ lõi như `api.js` (gọi HTTP API, tự động đính kèm Bearer token, xử lý refresh token/401 logout), `storage.js` (quản lý LocalStorage/SessionStorage an toàn).
  2. **Component Layer (`js/components/`):** Các thành phần giao diện dùng chung có tính độc lập cao:
     - `toast.js`: Thông báo góc màn hình (Success / Error / Warning).
     - `sidebar.js`: Điều hướng menu, quản lý trạng thái tab đang active, responsive mobile drawer.
     - `terminal-logs.js`: Console log hệ thống dạng streaming thời gian thực.
     - `modal.js`: Hộp thoại xác nhận, popup form.
  3. **Module Layer (`js/modules/`):** Từng tab chức năng nghiệp vụ riêng biệt tuân thủ Single Responsibility:
     - `system-config.js`: Quản lý cấu hình hệ thống & tích hợp mạng xã hội (Facebook, Google, Zalo, TikTok).
     - `ai-config.js`: Tinh chỉnh System Prompt, Knowledge Base, Onboarding limits của Faye AI.
     - `users.js`: Danh sách người dùng, tìm kiếm, lọc trạng thái, khóa/mở khóa tài khoản.
     - `ai-models.js`: Quản lý danh sách AI providers, đo lường độ trễ (latency/ping), toggle model.
     - `test-chat.js`: Giả lập phòng chat trực tiếp với AI để kiểm thử prompt.
     - `feedback.js`: Quản lý phản hồi đánh giá của người dùng.
  4. **Entry Point (`admin.js`):** Chỉ đóng vai trò bootstrap, khởi tạo event listeners và điều phối các module. Mỗi module không vượt quá **250 - 350 dòng**.

### B. Chuẩn Thẩm mỹ & Trải nghiệm Web Cosmic
- **Bảng màu:** Đồng bộ tuyệt đối với Mobile Design Tokens (`#6366F1` Indigo, `#EC4899` Pink, `#8B5CF6` Violet, `#0F172A` Slate Dark).
- **Cards & Inputs:** Border-radius tối thiểu `16px` cho card, `12px` cho input field. Sử dụng viền mảnh `border border-gray-200 dark:border-gray-800` kết hợp đổ bóng nhẹ `shadow-sm hover:shadow-md`.
- **Feedback tức thì (Immediate Feedback):** Mọi thao tác lưu cấu hình, đổi toggle, xóa hoặc thêm mới đều phải có Toast hiển thị kết quả và thay đổi trạng thái nút (Loading spinner) để người dùng an tâm.


