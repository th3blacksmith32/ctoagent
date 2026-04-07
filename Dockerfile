FROM node:23.3.0-slim

RUN apt-get update && apt-get install -y \
    python3 make g++ pkg-config git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9.15.1

WORKDIR /app

COPY . .

# Install and force-rebuild the database in one place
RUN pnpm install --ignore-scripts
RUN pnpm rebuild better-sqlite3
RUN pnpm build

EXPOSE 3000

# Start command using the loader
CMD ["node", "--loader", "ts-node/esm", "src/index.ts", "--character=characters/cto_agent.json"]
