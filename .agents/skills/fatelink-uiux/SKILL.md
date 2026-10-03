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
