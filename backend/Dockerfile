# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1: builder — install ALL deps, compile TypeScript to dist/
# ---------------------------------------------------------------------------
FROM node:24-bookworm-slim AS builder

WORKDIR /app

# Install dependencies first to leverage Docker layer caching.
# `npm ci` requires package-lock.json (present in the repo).
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build. `nest build` (nest-cli.json: sourceRoot=src,
# deleteOutDir=true) emits compiled JS to dist/.
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ---------------------------------------------------------------------------
# Stage 2: runtime — production deps only, run as non-root
# ---------------------------------------------------------------------------
FROM node:24-bookworm-slim AS runtime

ENV NODE_ENV=production

WORKDIR /app

# The `node` user already exists in the official node images.
# Create the app dir owned by it so the process can write if needed.
RUN mkdir -p /app && chown -R node:node /app

# Install ONLY production dependencies (devDependencies omitted).
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled output from the builder stage.
COPY --from=builder --chown=node:node /app/dist ./dist

# Run as the non-root `node` user.
USER node

EXPOSE 3001

# Liveness probe against the backend's /health endpoint (returns 200).
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://localhost:3001/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"

CMD ["node", "dist/main.js"]
