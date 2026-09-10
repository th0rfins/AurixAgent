FROM node:20-slim

# System deps for Playwright/Chromium.
# (curl + unzip needed to fetch the Bun runtime below)
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

# Use system Chromium for Playwright instead of downloading browsers
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# Install Bun explicitly (aurix's preferred runtime; avoids node:ffi issues
# with the terminal renderer modules that are statically imported)
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /app

# NOTE: copy the whole source BEFORE npm install, because package.json
# lifecycle scripts (postinstall, prepare) need scripts/ and src/ present.
COPY . .

# --ignore-scripts: we run postinstall + build explicitly below, in order
RUN npm install --ignore-scripts
RUN node scripts/postinstall.mjs
RUN npm run build

# Drop dev dependencies after build (typescript, eslint, tsx, ...)
RUN npm prune --production

RUN chmod +x /app/entrypoint.sh

# Expose nothing - this is a bot that connects outbound
# Railway will assign a PORT but we don't need it for gateway mode

CMD ["/app/entrypoint.sh"]
