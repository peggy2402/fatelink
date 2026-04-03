FROM node:20-slim

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# 🔥 XÓA dev deps sau khi build
RUN npm prune --omit=dev

CMD ["npm", "run", "start:prod"]