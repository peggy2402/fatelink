# 🚀 Git Workflow cho Team 2 Người (VSCode - Không dùng CLI)

## 🎯 Mục tiêu
- Làm việc nhóm an toàn
- Tránh conflict và mất code
- Không commit trực tiếp vào `main`

---

## 👨‍💻 PHẦN 1: Người tạo repo (Leader)

### 1. Push repo lên GitHub
- Đảm bảo project đã có trên GitHub

### 2. Mời collaborator
- Vào repo → Settings → Collaborators
- Add username GitHub của đồng đội
- Đồng đội accept email

---

## 👨‍💻 PHẦN 2: Người mới (máy mới)

### 1. Clone repo
- Mở VSCode
- `Ctrl + Shift + P` → `Git: Clone`
- Dán link repo
- Chọn thư mục lưu

### 2. Đăng nhập GitHub
- VSCode sẽ yêu cầu login
- Login qua trình duyệt

---

## 🔁 QUY TRÌNH LÀM VIỆC HÀNG NGÀY

### 🧑‍💻 Bước 1: Tạo branch riêng
- Click vào `main` (góc dưới trái VSCode)
- Chọn `Create new branch`
- Đặt tên:
  - `feature/login`
  - `feature/cart`

---

### ✍️ Bước 2: Code + Commit
- Sửa code
- Vào Source Control
- Nhập message
- Nhấn `Commit`
- Nhấn `Push` hoặc `Sync`

---

### 🔄 Bước 3: Tạo Pull Request
- Click `Create Pull Request` trên VSCode
- Hoặc vào GitHub → Compare & pull request

---

### 👀 Bước 4: Review + Merge
- Đồng đội kiểm tra code
- Nếu OK → Merge vào `main`

---

### 🔄 Bước 5: Cập nhật code mới
- Chuyển về `main`
- Nhấn `Pull`

---

### 🔁 Bước 6: Lặp lại
- Tạo branch mới cho task tiếp theo

---

## ⚠️ QUY TẮC QUAN TRỌNG

### ❌ Không làm
- Không commit trực tiếp vào `main`

### ✅ Nên làm
- Mỗi người 1 branch riêng
- Luôn Pull trước khi code
- Dùng Pull Request để merge

---

## 🔥 MẸO GIẢM CONFLICT

Trước khi code:
1. Checkout `main`
2. Pull latest code
3. Checkout lại branch của bạn

---

## 🧠 SƠ ĐỒ WORKFLOW

```
           main (ổn định)
               ↑
            merge (PR)
               ↑
   ---------------------------
   ↑                         ↑
feature/login         feature/cart
   ↑                         ↑
 Bạn code               Đồng đội code
```

---

## ✅ KẾT LUẬN
- Không commit vào main khi làm team
- Dùng branch + pull request
- VSCode hỗ trợ đầy đủ, không cần CLI

---

## 🚀 Nâng cao (tuỳ chọn)
- Thêm branch `develop`
- Flow: feature → develop → main
