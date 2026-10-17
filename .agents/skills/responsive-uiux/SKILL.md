---
name: responsive-uiux
description: Quy chuẩn thiết kế giao diện Web Responsive, khắc phục triệt để lỗi cuộn màn hình (Scroll-lock), tối ưu bố cục đa thiết bị (Mobile, Tablet, Desktop), Flexbox/Grid chống tràn nội dung và trải nghiệm người dùng cao cấp cho FateLink Web & Mobile.
---

# Responsive Web & UI/UX Design System Guidelines

> Bản quy chuẩn thiết kế trải nghiệm người dùng (UX) và kỹ thuật dàn trang Responsive thích ứng mọi kích thước màn hình cho các hệ thống Web Dashboard, Admin Console và Portal của **FateLink**.

---

## 1. Nguyên tắc Vàng về Kiến trúc Khung nhìn (Viewports & Scroll Architecture)

### A. Triệt tiêu Lỗi Scroll-Lock (Không cuộn được nội dung)
Lỗi phổ biến nhất trong các web app hiện đại là đặt `overflow-hidden` trên khung ngoài nhưng quên hoặc cấu hình sai vùng chứa con, dẫn tới việc người dùng không thể cuộn xem hết nội dung.

**Quy tắc bất biến:**
1. Khung chứa gốc (`body`, `#dashboardScreen`): Đặt `h-screen flex overflow-hidden`.
2. Khung nội dung chính (`Main Content Wrapper`): Đặt `flex-1 flex flex-col min-w-0 overflow-hidden relative`.
3. Header (`<header>`): Đặt `shrink-0 z-10 sticky top-0`.
4. Vùng cuộn thực thụ (`<main>`): **BẮT BUỘC** phải có các thuộc tính:
   ```html
   <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-100 p-4 sm:p-6 pb-28">
       <!-- Toàn bộ nội dung các Tabs hoặc Page đặt tại đây -->
   </main>
   ```
5. **Khoảng thở an toàn ở chân trang (`pb-28` hoặc `pb-32`):** Luôn chừa padding đáy rộng rãi để các thanh công cụ dính đáy (`sticky bottom-4` hoặc `fixed bottom`) không bao giờ che khuất trường nhập liệu hay nút bấm cuối cùng.

---

## 2. Tiêu chuẩn Phân giải màn hình (Breakpoints System)

| Breakpoint | Kích thước | Hành vi giao diện |
| :--- | :--- | :--- |
| **Mobile** | `< 640px` (`sm`) | Sidebar biến thành Drawer trượt ra, có màng phủ mờ (`backdrop-blur`). Header có nút Hamburger (`fa-bars`). Lưới đơn cột (`grid-cols-1`). |
| **Tablet** | `640px - 1024px` (`md`) | Lưới 2 cột (`grid-cols-2`). Thanh tìm kiếm và bộ lọc gom nhóm theo hàng ngang. Drawer tự động đóng khi chọn tab. |
| **Desktop** | `> 1024px` (`lg` / `xl`) | Sidebar cố định (`w-64 shrink-0`). Nội dung dàn trải cân đối với `max-w-5xl` hoặc `max-w-7xl` căn giữa (`mx-auto`). |

---

## 3. Quy chuẩn Thành phần Tương tác (Interactive Components)

### A. Sticky Action Bars (Thanh công cụ cố định đáy)
Thay vì nút trôi nổi che khuất nội dung, sử dụng thiết kế Floating Glass Bar:
```html
<div class="sticky bottom-4 z-20 bg-white/95 backdrop-blur-md border border-gray-200/90 rounded-2xl p-4 shadow-xl flex flex-col sm:flex-row items-center justify-between gap-3">
    <div class="text-xs sm:text-sm text-gray-500 flex items-center space-x-2">
        <i class="fas fa-info-circle text-blue-500"></i>
        <span>Thông tin trạng thái hoặc lưu ý quan trọng.</span>
    </div>
    <button class="w-full sm:w-auto px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-md transition transform active:scale-95">
        Lưu thay đổi
    </button>
</div>
```

### B. Input Fields & Form Usability
- **Touch Target:** Chiều cao tối thiểu của ô nhập liệu hoặc nút bấm trên thiết bị cảm ứng là **44px** (`py-2.5` hoặc `py-3`).
- **Font Size chống Auto-Zoom:** Cỡ chữ trong input phải từ **14px** trở lên (trên iOS Safari, font nhỏ hơn 16px có thể kích hoạt auto-zoom gây vỡ bố cục nếu không kiểm soát).
- **Sao chép 1 chạm (Click-to-copy):** Mọi App ID, Token, Secret Key, Client ID phải có nút Copy nhanh kèm thông báo trực quan qua Toast.
- **Ẩn/Hiện Mật khẩu (Toggle Visibility):** Các trường nhạy cảm (`App Secret`, `API Key`) mặc định đặt `type="password"` kèm nút bấm chuyển sang `type="text"`.

---

## 4. Tối ưu Hiệu năng & Trải nghiệm (UX Polish)

1. **State Preservation:** Lưu giữ tab đang chọn vào `localStorage` để khi F5 / reload trang không bị văng về tab đầu tiên.
2. **Scrollbar Thẩm mỹ:** Tùy biến thanh cuộn với CSS mỏng, màu trung tính nhạt (`custom-scrollbar`), không để thanh cuộn mặc định thô cứng của trình duyệt làm giảm tính thẩm mỹ.
3. **Empty States & Feedback:** Luôn có biểu tượng minh họa và lời giải thích thân thiện khi danh sách trống.
