FROM node:20-slim AS base

# Prevent npm install warnings
ENV NPM_CONFIG_LOGLEVEL=warn
# Set working directory
WORKDIR /app

# ---- BUILD STAGE ----
FROM base AS builder

# Copy package files
COPY package.json package-lock.json ./
COPY server/package.json server/
COPY client/package.json client/

# Install dependencies
RUN npm run install:all

# Copy source code
COPY . .

# Build client
WORKDIR /app/client
RUN npm run build

# Build server (TypeScript to JavaScript)
WORKDIR /app/server
RUN npx tsc

# ---- PRODUCTION STAGE ----
FROM base AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
# Default port for Google Cloud Run
ENV PORT=8080

# Copy root package.json
COPY package.json ./

# Copy server files and install ONLY production dependencies
COPY server/package.json ./server/
WORKDIR /app/server
RUN npm install --omit=dev

# Copy built server files
COPY --from=builder /app/server/dist ./dist

# Copy built client files to be served by the backend
COPY --from=builder /app/client/dist ./client-dist

# Create a non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 expressjs
USER expressjs

# Expose port
EXPOSE 8080

# Start the server
CMD ["node", "dist/index.js"]