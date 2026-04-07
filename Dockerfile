FROM node:23.3.0-slim

# Install system essentials for compiling the database
RUN apt-get update && apt-get install -y \
    python3 make g++ pkg-config git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9.15.1

WORKDIR /app

# Copy everything
COPY . .

# 1. Install dependencies (ignoring scripts to bypass audio errors)
RUN pnpm install --ignore-scripts

# 2. FORCE REBUILD only the database in place
RUN pnpm rebuild better-sqlite3

# 3. Compile the TypeScript
RUN pnpm build

EXPOSE 3000

# Start directly
CMD ["node", "--loader", "ts-node/esm", "src/index.ts", "--character=characters/cto_agent.json"]
