# Hướng dẫn viết Tài liệu Ý tưởng (Concept Document)

## 1. Mục tiêu của tài liệu ý tưởng
Tài liệu Ý tưởng chỉ tập trung trả lời các câu hỏi cốt lõi:
- **Vì sao cần làm?**
- **Đang giải quyết vấn đề gì?**
- **Giá trị mang lại là gì?**
- **Phạm vi lớn của nhánh này là gì?**

## 2. Cấu trúc nội dung (Nên có gì)
- **Mục tiêu:** Định hướng chính của ý tưởng.
- **Bối cảnh:** Tại sao cần thực hiện tại thời điểm này.
- **Giá trị mang lại:** Lợi ích cho người dùng hoặc hệ thống.
- **Phạm vi:** Các ranh giới hoặc định hướng triển khai.
- **Kết quả mong muốn:** Định nghĩa về sự thành công.
- **Hướng mở rộng:** Các khả năng phát triển trong tương lai (nếu cần).

## 3. Những nội dung không nên có
Để tránh làm loãng tài liệu, không đưa vào:
- Endpoint
- DTO (Data Transfer Object)
- Schema dữ liệu
- Sequence kỹ thuật
- Task triển khai cụ thể
- Mô tả luồng chi tiết từng bước

## 4. Dấu hiệu viết đúng
Người đọc sau khi xem tài liệu sẽ hiểu được:
- Tại sao nhánh này tồn tại.
- Nhánh này có đáng làm hay không (giá trị thực tế).
- Nhánh này sẽ dẫn tới những chức năng/trải nghiệm cụ thể nào.

## 5. Dấu hiệu viết sai
- Đọc giống như tài liệu kỹ thuật backend.
- Liệt kê danh sách API.
- Chốt quá nhiều chi tiết hành vi (lạm bàn về "cách làm" thay vì "tại sao làm").
- Viết quá dài dòng nhưng không làm rõ được vấn đề trọng tâm.

## 6. Ví dụ minh họa: Đăng nhập
- **Mục tiêu:** Cho phép người dùng truy cập lại tài khoản nhanh và thuận tiện.
- **Giá trị:** Giảm ma sát cho người dùng khi quay lại ứng dụng.
- **Phạm vi:** Tập trung vào các cách đăng nhập ưu tiên như Google, email, số điện thoại.
