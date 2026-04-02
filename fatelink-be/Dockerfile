FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

# 🔥 CÀI FULL (KHÔNG omit dev)
RUN npm install

COPY . .

RUN npm run build

# 🔥 XÓA dev deps sau khi build
RUN npm prune --omit=dev

CMD ["npm", "run", "start:prod"]