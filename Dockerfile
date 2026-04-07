FROM node:23.3.0-slim AS builder

RUN apt-get update && apt-get install -y \
    python3 make g++ pkg-config libcairo2-dev libpango1.0-dev git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9.15.1

WORKDIR /app

COPY package.json pnpm-lock.yaml* .npmrc* tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
COPY characters ./characters

# Install without scripts to bypass the broken audio libraries
RUN pnpm install --ignore-scripts

# Build the project to generate the /dist folder
RUN pnpm build

# --- Runtime ---
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

# We use 'pnpm start' but ensure the environment is ready
CMD ["pnpm", "start", "--character=characters/cto_agent.json"]
