FROM node:23.3.0-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9.15.1

WORKDIR /app

# Copy config and source
COPY package.json pnpm-lock.yaml* .npmrc* tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
COPY characters ./characters

# --- THE FIX ---
# 1. Install without scripts (skips broken stuff)
RUN pnpm install --ignore-scripts
# 2. Rebuild ONLY the database (makes it work on Railway)
RUN pnpm rebuild better-sqlite3
# 3. Build the agent
RUN pnpm build

# --- Runtime Stage ---
FROM node:23.3.0-slim
RUN npm install -g pnpm@9.15.1
RUN apt-get update && apt-get install -y git python3 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/characters ./characters
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/tsconfig.json ./

EXPOSE 3000

# Final start command
CMD ["pnpm", "start", "--character=characters/cto_agent.json"]
