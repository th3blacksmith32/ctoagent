# Use Node 23 as the base image
FROM node:23.3.0-slim AS builder

# Install system dependencies needed for native C++ modules (Canvas, SQLite, etc.)
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

# Install pnpm globally
RUN npm install -g pnpm@9.15.1

# Set the working directory
WORKDIR /app

# Copy the core configuration files
# Note: This assumes you are using the Eliza-Starter or Full Repo structure
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* .npmrc ./
COPY agent ./agent
COPY packages ./packages
COPY scripts ./scripts
COPY characters ./characters

# Install all dependencies
RUN pnpm install

# Build the project
RUN pnpm build

# Final Runtime Image
FROM node:23.3.0-slim
RUN npm install -g pnpm@9.15.1
RUN apt-get update && apt-get install -y git python3 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built files from the builder stage
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/agent ./agent
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/characters ./characters

# Expose the Dashboard port
EXPOSE 3000

# Start the agent using the character path from your Railway variables
CMD ["pnpm", "start", "--character=characters/cto_agent.json"]
