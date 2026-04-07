# Use Node 23 slim as the base
FROM node:23.3.0-slim AS builder

# Install system dependencies required for native modules (Canvas, SQLite, etc.)
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

# Install pnpm
RUN npm install -g pnpm@9.15.1

WORKDIR /app

# Copy dependency files first for better caching
COPY package.json pnpm-lock.yaml* .npmrc ./

# Copy the actual code folders present in your repo
COPY src ./src
COPY scripts ./scripts
COPY characters ./characters
COPY tsconfig.json ./

# Install all dependencies
RUN pnpm install

# Build the project
RUN pnpm build

# --- Runtime Stage ---
FROM node:23.3.0-slim

# Install runtime-only essentials
RUN npm install -g pnpm@9.15.1
RUN apt-get update && apt-get install -y git python3 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy necessary files from builder
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/characters ./characters
COPY --from=builder /app/dist ./dist

# Expose the API/Dashboard port
EXPOSE 3000

# Start the agent using your character file
# Railway's CHARACTER_PATH variable will override this if set, 
# but this is the safe default.
CMD ["pnpm", "start", "--character=characters/cto_agent.json"]
