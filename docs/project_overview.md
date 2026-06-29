# 🔗 FateLink – Tổng quan Dự án

> **Một hệ sinh thái kết nối cảm xúc bằng AI** — ghép đôi người dùng dựa trên phân tích cảm xúc & tính cách sâu, không phải ngoại hình.

---

## 🗂️ Cấu trúc Monorepo

```
fatelink/
├── fatelink-be/        ← Backend: NestJS + MongoDB
├── fatelinkfe/         ← Frontend: Flutter (iOS/Android)
└── memories.md         ← Dev journal (nhật ký phát triển)
```

---

## 🔧 Backend — `fatelink-be` (NestJS)

### Kiến trúc: Clean Architecture + DDD (Domain-Driven Design)

```
src/
├── main.ts
├── app.module.ts
├── app.controller.ts
├── composition/
│   ├── composition-root.module.ts   ← DI Root (kết nối tất cả module)
│   └── primary-adapters.module.ts
├── shared/                          ← Shared utilities
└── contexts/                        ← Domain Bounded Contexts
    ├── admin/                       ← Quản trị hệ thống
    ├── ai/                          ← AI Engine (Strategy Pattern)
    │   ├── application/
    │   │   ├── services/
    │   │   │   └── ai-text-generation.service.ts
    │   │   └── usecases/
    │   └── composition/
    ├── auth/                        ← Xác thực (Google OAuth + JWT)
    │   ├── application/
    │   ├── domain/
    │   ├── infrastructure/
    │   └── presentation/
    ├── chat/                        ← Real-time Chat (WebSocket/Socket.IO)
    │   ├── application/
    │   ├── domain/
    │   ├── infrastructure/
    │   └── presentation/
    ├── matching/                    ← Thuật toán Matchmaking
    │   ├── application/
    │   ├── domain/
    │   └── infrastructure/
    ├── support/                     ← Hỗ trợ người dùng (Discord Webhook)
    └── users/                       ← Quản lý người dùng
        ├── application/
        ├── domain/
        │   ├── entities/
        │   └── repositories/
        ├── infrastructure/
        └── presentation/
```

### 🤖 AI Engine (Fallback Chain)
```
Gemini (gemini-2.0-flash-exp)
  ↓ [lỗi 404 / Rate Limit]
LlamaLocal (tắt khi production)
  ↓
OpenAI (gpt-4o-mini)
  ↓
HuggingFace (Qwen2.5-7B-Instruct)
  ↓
MockAI (chốt chặn, không bao giờ crash)
```

### 🎯 Các API chính
| Module | Endpoint | Chức năng |
|--------|----------|-----------|
| Auth | `POST /auth/google` | Xác thực Google OAuth, trả JWT |
| Users | `GET /users/:id/profile` | Profile + Deep Analytics |
| Users | `PATCH /users/emotion` | Cập nhật trạng thái cảm xúc |
| Matching | `GET /matching/candidates` | Danh sách ứng viên ghép đôi |
| Matching | `POST /matching/unmatch` | Hủy ghép đôi |
| Chat | WebSocket `chat` | Real-time chat (Faye AI + Match Chat) |
| Support | `POST /support` | Gửi yêu cầu hỗ trợ |
| Admin | `/admin/*` | Dashboard quản trị (JWT protected) |
| Static | `/privacy.html`, `/terms.html` | Trang điều khoản |

### 🛠️ Tech Stack Backend
- **Runtime**: Node.js 20 / NestJS
- **Database**: MongoDB + Mongoose (ODM)
- **Auth**: JWT + Google Auth Library
- **AI**: Gemini (`@google/genai`), OpenAI, HuggingFace, node-llama-cpp
- **Real-time**: Socket.IO (WebSocket Gateway)
- **Notifications**: Firebase Admin SDK (FCM)
- **Deploy**: Fly.io + Docker + GitHub Actions CI/CD
- **Admin UI**: HTML/JS thuần + TailwindCSS + Chart.js (serve qua ServeStaticModule)

### 🧮 Thuật toán Matchmaking
- **Khoảng cách Euclidean** (40%) → tương đồng tính cách
- **Ma trận bù trừ cảm xúc** (60%) → bổ sung cảm xúc (Complementary)
- **EMA (Exponential Moving Average)**: làm mượt vector cảm xúc (80/20) và tính cách (90/10) — chống nhiễu dữ liệu tạm thời

---

## 📱 Frontend — `fatelinkfe` (Flutter)

### Kiến trúc: Clean Architecture + BLoC (Business Logic Component)

```
lib/
├── main.dart                        ← Entry point, DI setup, Error handling
├── core/
│   ├── constants/                   ← App constants (URLs, keys...)
│   ├── router/
│   │   └── app_router.dart          ← Centralized routing
│   ├── theme/
│   │   ├── app_theme.dart           ← Material 3 Premium Dark Theme
│   │   └── app_colors.dart          ← Color system
│   └── utils/                       ← Shared utilities (ToastUtil...)
├── data/
│   ├── models/
│   │   ├── chat_message.dart
│   │   └── match_user.dart
│   ├── providers/                   ← Data providers
│   └── repositories/
│       ├── chat_repository.dart
│       ├── home_repository.dart
│       ├── matches_repository.dart
│       └── profile_repository.dart
├── logic/
│   └── blocs/
│       ├── auth/                    ← AuthBloc (login, logout, token check)
│       ├── chat/                    ← ChatBloc (Faye AI + history)
│       ├── home/                    ← HomeBloc (anonymous users feed)
│       ├── main/                    ← MainBloc (tab navigation)
│       ├── matches/                 ← MatchesBloc (matchmaking list)
│       ├── profile/                 ← ProfileBloc (user data + radar chart)
│       └── splash/                  ← SplashBloc (auto-login check)
├── presentation/
│   ├── screens/
│   │   ├── splash/                  ← Cinematic splash screen
│   │   ├── onboarding/              ← 3-step PageView onboarding
│   │   ├── login/                   ← Google Sign-In screen
│   │   ├── home/                    ← Anonymous users feed
│   │   ├── chat/                    ← Faye AI chat screen
│   │   ├── match/                   ← Match chat screen
│   │   ├── explore/                 ← Explore tab
│   │   ├── profile/                 ← User profile + Radar Chart
│   │   ├── settings/                ← App settings
│   │   └── main_screen.dart         ← Dashboard (IndexedStack)
│   └── widgets/                     ← Shared reusable widgets
└── services/
    ├── api_service.dart             ← HTTP wrapper (auto 401 redirect)
    └── fcm_service.dart             ← Firebase Cloud Messaging
```

### 🎨 Design System
- **Theme**: Premium Dark Space (`#0A0514` nền đen không gian)
- **Tone màu chủ đạo**: Xanh dương đậm + Trắng (công nghệ, hiện đại)
- **Gradient**: Mesh Gradient (Neon Purple + Soft Pink)
- **Glassmorphism**: Nhiều màn hình (Bottom Nav, Profile, Cards)
- **Animation**: 60fps, Spring Physics (`elasticOut`), Lottie

### 📱 Luồng Trải nghiệm Người dùng (UX Flow)
```
App launch
  └─ SplashScreen (3s, cinematic)
       └─ is_first_time?
           ├─ YES → OnboardingScreen (3 slides)
           └─ NO  → AuthBloc check token
                      ├─ Valid  → MainScreen (Home/Chat/Match/Profile)
                      └─ Invalid → LoginScreen (Google Sign-In)
```

### 🔄 Luồng AI Onboarding (Phase 1 → 2)
```
LoginScreen
  └─ ChatScreen (Faye AI)
       ├─ AI hỏi về cảm xúc → User chọn Emotion Chips
       ├─ AI phân tích → cập nhật vector cảm xúc + tính cách
       ├─ is_ready_to_match: true?
       │     └─ matchReady event (Socket.IO)
       │          └─ Popup "✨ Đã thấu hiểu tâm hồn"
       │               └─ MatchesScreen (Phase 2)
       └─ FloatingAiBubble (chat Faye từ mọi màn hình)
```

### 🧩 BLoC Architecture
| BLoC | Events | States |
|------|--------|--------|
| `AuthBloc` | LoginRequested, LogoutRequested, CheckToken | Authenticated, Unauthenticated, Loading |
| `ChatBloc` | SendMessage, LoadHistory | ChatLoaded, ChatTyping, ChatError |
| `HomeBloc` | LoadUsers, LoadMore | HomeLoading, HomeLoaded, HomeError |
| `MatchesBloc` | LoadMatches, LoadMoreMatches, UnmatchUser | MatchesLoaded, MatchesError |
| `ProfileBloc` | LoadProfile | ProfileLoaded, ProfileError |
| `SplashBloc` | AppStarted | SplashNavigating |

### 📦 Key Dependencies (pubspec.yaml)
- `flutter_bloc` — State management
- `easy_localization` — i18n (Tiếng Việt / English)
- `socket_io_client` — Real-time WebSocket
- `firebase_messaging` — Push notifications (FCM)
- `flutter_secure_storage` — Token storage (Keychain/Keystore)
- `fl_chart` — Radar Chart (emotion visualization)
- `shared_preferences` — Onboarding flag, bubble position
- `url_launcher` — Open terms/privacy pages
- `google_sign_in` — Google OAuth

---

## 🔗 Liên kết Backend ↔ Frontend

| Tính năng | Backend | Frontend |
|-----------|---------|----------|
| Xác thực | JWT + Google Auth | `AuthBloc` + `flutter_secure_storage` |
| AI Chat (Faye) | `ChatGateway` (Socket.IO) + `AiService` | `ChatBloc` + `socket_io_client` |
| Matchmaking | `MatchmakingService` (Euclidean + EMA) | `MatchesBloc` + `MatchesScreen` |
| Push Notif | `NotificationService` (Firebase Admin) | `FcmService` + `firebase_messaging` |
| Profile Analytics | `GET /users/:id/profile` | `ProfileBloc` + `fl_chart` Radar |
| Admin | Admin Dashboard HTML/JS | Web Browser |

---

## 🚀 Deployment

| Component | Platform | CI/CD |
|-----------|----------|-------|
| Backend | **Fly.io** (Docker, Node 20) | GitHub Actions |
| Database | **MongoDB Atlas** | — |
| AI Models | Gemini API, OpenAI API, HuggingFace | — |
| Push Notif | **Firebase** (FCM) | — |

---

## 📋 Trạng thái hiện tại (tính đến 29/06/2026)

### ✅ Đã hoàn thành
- Toàn bộ luồng Auth (Google Sign-In → JWT → Auto-login)
- AI Chat với Faye (real-time Socket.IO, AI Onboarding Phase 1)
- Thuật toán Matchmaking (Euclidean + Complementary, EMA smoothing)
- Admin Dashboard (User/AI management, Chart.js, Ping Check)
- Push Notifications (FCM, foreground + background)
- BLoC refactor toàn bộ Flutter app
- i18n Tiếng Việt / Tiếng Anh
- CI/CD deploy Fly.io

### 🔲 Cần làm tiếp
- `EditProfileScreen` — cập nhật thông tin cá nhân
- Infinite scroll cho `HomeScreen`
- Settings screen (biometric, notification toggles, privacy controls)
- AI Onboarding mới: thay 3-slide tĩnh bằng AI Chat
- Mở rộng emotion system (hiện 6 → mục tiêu 8 nhóm)
- FateLink Settings center (full feature list theo concept doc)
