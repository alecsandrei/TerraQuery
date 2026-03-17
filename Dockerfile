FROM node:22-slim AS base
WORKDIR /app
ENV NPM_CONFIG_LOGLEVEL=warn

# ---- BUILD STAGE ----
FROM base AS builder
COPY package.json package-lock.json ./
COPY server/package.json server/
COPY client/package.json client/
RUN npm run install:all
COPY . .
# Build client
RUN cd client && npm run build
# Build server
RUN cd server && npx tsc

# ---- PRODUCTION STAGE ----
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
COPY --from=builder /app/package.json ./
COPY --from=builder /app/server/package.json ./server/
RUN cd server && npm install --omit=dev
COPY --from=builder /app/server/dist ./server/dist
COPY --from=builder /app/client/dist ./client-dist
# Create a non-root user
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 expressjs
USER expressjs
EXPOSE 8080
WORKDIR /app/server
CMD ["node", "dist/index.js"]