# Dockerfile for streamer-web
FROM node:18-alpine

RUN apk add --no-cache ffmpeg

WORKDIR /app
COPY package.json ./
COPY server/tsconfig.json ./server/tsconfig.json
COPY server/src ./server/src
COPY web ./web

RUN npm install && npm run build

ENV PORT=3000 \
    VIDEOS_DIR=/videos \
    WEB_DIR=/app/web

EXPOSE 3000
CMD ["npm", "start"]
