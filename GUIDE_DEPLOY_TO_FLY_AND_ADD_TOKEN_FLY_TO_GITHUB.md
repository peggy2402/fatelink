# 🚀 GUIDE: DEPLOY NESTJS TO FLY.IO + AUTO DEPLOY WITH GITHUB ACTIONS

---

# 🧱 PHẦN 1: DEPLOY NESTJS LÊN FLY.IO

## 🔹 B1: Cài Fly CLI
iwr https://fly.io/install.ps1 -useb | iex

Check:
flyctl version

---

## 🔹 B2: Login
flyctl auth login

---

## 🔹 B3: Sửa main.ts
await app.listen(process.env.PORT || 3000, '0.0.0.0');

---

## 🔹 B4: Sửa package.json
"start:prod": "node dist/src/main.js"

---

## 🔹 B5: Tạo Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

RUN npm prune --omit=dev

CMD ["npm","run","start:prod"]

---

## 🔹 B6: Tạo .dockerignore
node_modules
dist
.git
.env

---

## 🔹 B7: Set secrets (.env)
flyctl secrets set MONGODB_URI="xxx"
flyctl secrets set JWT_SECRET="xxx"
flyctl secrets set GOOGLE_CLIENT_ID="xxx"
flyctl secrets set DISCORD_WEBHOOKS_CLIENT="xxx"
flyctl secrets set GEMINI_API_KEY="xxx"

---

## 🔹 B8: Xóa app cũ (nếu có)
flyctl apps destroy fatelink-be

---

## 🔹 B9: Tạo lại app
flyctl launch

---

## 🔹 B10: Cấu hình
TẮT:
- Postgres → none
- Redis → none
- Storage → off

GIỮ:
- Port: 3000
- Region: sin
- RAM: 256MB

---

## 🔹 B11: Deploy
flyctl deploy --local-only

---

## 🔹 B12: Xem log
flyctl logs

---

# ⚙️ PHẦN 2: AUTO DEPLOY BẰNG GITHUB ACTIONS

## 🔹 B1: Lấy token
flyctl auth token

---

## 🔹 B2: Thêm vào GitHub
Name: FLY_API_TOKEN

---

## 🔹 B3: Tạo file
.github/workflows/deploy.yml

---

## 🔹 B4: Nội dung
name: Deploy to Fly

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: fatelink-be

    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

---

## 🔹 B5: Push
git add .
git commit -m "setup CI/CD"
git push

---

# 🚀 DONE
