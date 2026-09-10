FROM node:20-slim

# Install system dependencies for Playwright/Chromium
# (curl + unzip needed by postinstall to fetch the Bun runtime)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    chromium \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Set Chromium env for Playwright
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --production=false

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Clean up dev dependencies after build
RUN npm prune --production

# Entrypoint generates ~/.aurix/config.yaml from env vars at startup
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose nothing - this is a bot that connects outbound
# Railway will assign a PORT but we don't need it for gateway mode

CMD ["/app/entrypoint.sh"]
