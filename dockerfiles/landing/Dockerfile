FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm install --only=production

# Copy app source
COPY server.js ./
COPY views ./views
COPY public ./public

EXPOSE 8080
CMD ["node", "server.js"]
