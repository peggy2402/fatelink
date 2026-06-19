# Fatelink Project Structure Prompt

## Prompt sử dụng lại

Bạn đang làm việc trong project `fatelink`, một monorepo gồm 2 phần chính:

- `fatelink-be`: backend NestJS/TypeScript.
- `fatelinkfe`: frontend Flutter/Dart.

Hãy đọc và hiểu cấu trúc project trước khi chỉnh sửa code. Ưu tiên giữ đúng kiến trúc hiện có, không tự ý đổi cách tổ chức thư mục nếu không cần thiết.

## Tổng quan cấu trúc

```text
fatelink/
├── fatelink-be/              # Backend NestJS
├── fatelinkfe/               # Frontend Flutter
├── .github/                  # Cấu hình GitHub
├── .vscode/                  # Cấu hình VS Code
├── README.md                 # Tài liệu tổng quan
├── SYSTEMREADME.md           # Tài liệu hệ thống
├── GUIDESETTINGS.md          # Hướng dẫn cấu hình
├── GUIDE_DEPLOY_TO_FLY_AND_ADD_TOKEN_FLY_TO_GITHUB.md
├── PROMPT.md                 # Prompt/tài liệu hướng dẫn sẵn có
├── CODEWITHTEAM.md           # Ghi chú làm việc nhóm
├── memories.md               # Ghi chú/memory project
└── FATELINK_SYSTEM.drawio.png
```

## Backend: `fatelink-be`

Backend dùng NestJS, TypeScript và được tổ chức theo hướng domain/context.

```text
fatelink-be/
├── src/
│   ├── main.ts               # Điểm khởi chạy backend
│   ├── app.module.ts         # Module gốc của NestJS
│   ├── app.controller.ts
│   ├── composition/          # Ghép module, dependency, primary adapters
│   ├── contexts/             # Các domain chính của hệ thống
│   │   ├── admin/
│   │   ├── ai/
│   │   ├── auth/
│   │   ├── chat/
│   │   ├── matching/
│   │   ├── support/
│   │   └── users/
│   └── shared/               # Code dùng chung toàn backend
├── public/                   # Trang tĩnh: privacy, terms, support...
├── test/                     # E2E tests
├── tools/                    # Script generate API
├── docs/                     # Tài liệu backend
├── logs/                     # Log runtime/admin
├── package.json              # Scripts và dependencies Node/NestJS
├── tsconfig.json
├── tsconfig.build.json
├── nest-cli.json
├── Dockerfile
├── vercel.json
├── .env
└── .env.example
```

### Kiến trúc backend theo context

Mỗi context/domain thường có các lớp sau:

```text
contexts/<domain>/
├── application/              # Use case, service nghiệp vụ
├── composition/              # Module wiring/dependency injection
├── domain/                   # Entity, repository interface, rule cốt lõi
├── infrastructure/           # Model DB, repository implementation, service ngoài
└── presentation/             # HTTP controller, WebSocket gateway, DTO
```

Các context chính:

- `admin`: chức năng quản trị.
- `ai`: xử lý AI/provider/use case liên quan AI.
- `auth`: xác thực, đăng nhập, token.
- `chat`: chat, lịch sử chat, WebSocket.
- `matching`: logic ghép đôi/matching.
- `support`: hỗ trợ người dùng.
- `users`: hồ sơ và dữ liệu người dùng.

Thư mục `shared/` chứa phần dùng chung:

```text
shared/
├── contracts/                # Interface/service contract dùng chung
├── errors/                   # Application error
├── infrastructure/           # Provider AI, module hạ tầng chung
├── kernel/                   # Token, vector, primitive dùng lõi
├── presentation/             # Filter/type dùng ở layer presentation
└── testing/                  # Helper test
```

## Frontend: `fatelinkfe`

Frontend dùng Flutter/Dart, có BLoC/state management và chia lớp tương đối rõ.

```text
fatelinkfe/
├── lib/
│   ├── core/                 # Cấu hình lõi
│   │   ├── constants/
│   │   ├── router/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/                 # Data layer
│   │   ├── models/
│   │   ├── providers/
│   │   └── repositories/
│   ├── logic/                # Business/state layer
│   │   └── blocs/
│   │       ├── auth/
│   │       ├── chat/
│   │       ├── home/
│   │       ├── main/
│   │       ├── matches/
│   │       ├── profile/
│   │       └── splash/
│   ├── presentation/         # UI layer
│   │   ├── screens/
│   │   │   ├── chat/
│   │   │   ├── explore/
│   │   │   ├── home/
│   │   │   ├── login/
│   │   │   ├── match/
│   │   │   ├── onboarding/
│   │   │   ├── profile/
│   │   │   ├── settings/
│   │   │   └── splash/
│   │   └── widgets/
│   └── services/             # API service, FCM service
├── assets/
│   ├── icon/
│   ├── images/
│   └── translations/         # en.json, vi.json
├── android/
├── ios/
├── ios_backup/
├── macos/
├── linux/
├── windows/
├── web/
├── test/
├── pubspec.yaml              # Dependencies và asset config
├── pubspec.lock
└── analysis_options.yaml
```

### Vai trò các lớp frontend

- `core`: cấu hình chung như route, theme, constants, utilities.
- `data`: model dữ liệu, provider gọi API/local storage, repository.
- `logic`: BLoC và state/event xử lý luồng nghiệp vụ.
- `presentation`: màn hình và widget hiển thị cho người dùng.
- `services`: service tích hợp như API và Firebase Cloud Messaging.

## Công nghệ chính

Backend:

- NestJS 11.
- TypeScript.
- MongoDB/Mongoose.
- TypeORM/PostgreSQL.
- Socket.IO/WebSocket.
- Firebase Admin.
- OpenAI, Gemini/Google GenAI, Claude, HuggingFace, Llama provider.
- Jest cho unit/e2e test.

Frontend:

- Flutter.
- Dart SDK `^3.11.4`.
- `flutter_bloc`.
- `easy_localization`.
- `socket_io_client`.
- `firebase_core`, `firebase_messaging`.
- `google_sign_in`.
- `http`, `shared_preferences`, `flutter_secure_storage`.

## Nguyên tắc khi làm việc với project

1. Với backend, thêm/sửa tính năng theo đúng context tương ứng trong `src/contexts`.
2. Không đặt logic nghiệp vụ vào controller nếu đã có use case/service trong `application`.
3. Entity và rule lõi nên nằm trong `domain`.
4. Kết nối database, provider ngoài và implementation cụ thể nên nằm trong `infrastructure`.
5. DTO, controller, gateway và filter liên quan request/response nên nằm trong `presentation`.
6. Với frontend, UI đặt trong `presentation`, state đặt trong `logic/blocs`, dữ liệu đặt trong `data`.
7. Các widget dùng lại nên đưa vào `presentation/widgets`.
8. Cấu hình chung như theme, route, constants nên để trong `core`.
9. Không sửa file generated/platform nếu không thật sự cần.
10. Khi thêm asset Flutter, nhớ khai báo trong `pubspec.yaml` nếu asset chưa nằm trong folder đã khai báo.

## Prompt mẫu cho AI/code assistant

```text
Bạn là trợ lý lập trình đang làm việc trong project Fatelink.

Project này gồm:
- Backend NestJS ở `fatelink-be`.
- Frontend Flutter ở `fatelinkfe`.

Trước khi chỉnh sửa, hãy đọc cấu trúc liên quan và giữ đúng kiến trúc hiện có.

Backend được chia theo context/domain trong `fatelink-be/src/contexts`, gồm:
- admin
- ai
- auth
- chat
- matching
- support
- users

Mỗi context thường theo các lớp:
- application: use case/service nghiệp vụ
- domain: entity, repository interface, rule lõi
- infrastructure: model DB, implementation, provider ngoài
- presentation: controller, DTO, gateway
- composition: module wiring/dependency injection

Frontend Flutter nằm trong `fatelinkfe/lib`, gồm:
- core: constants, router, theme, utils
- data: models, providers, repositories
- logic: blocs/state management
- presentation: screens và widgets
- services: API service, FCM service

Khi thực hiện yêu cầu:
1. Xác định yêu cầu thuộc backend, frontend hay cả hai.
2. Tìm đúng context hoặc layer trước khi sửa.
3. Giữ style code và cấu trúc hiện có.
4. Không refactor ngoài phạm vi nếu không cần.
5. Sau khi sửa, chạy test/lint phù hợp nếu có thể.
6. Tóm tắt rõ file đã sửa và cách kiểm tra.
```
