FROM node:18-alpine

WORKDIR /app
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN mkdir -p /app/data /app/logs

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "console.log('Bot health check')" || exit 1

CMD ["node", "arbitrageBot.js"]
