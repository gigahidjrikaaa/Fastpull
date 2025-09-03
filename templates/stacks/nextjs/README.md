# Deploying a Next.js App with Fastpull

This stack uses Docker Compose for a simple and robust deployment.

## 1. Dockerfile

Add a `Dockerfile` to your Next.js project root:

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# 1. Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# 2. Build the app
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# 3. Production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
RUN chown nextjs:nodejs .
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```
*Note: This Dockerfile assumes you have `output: 'standalone'` in your `next.config.js`.*

## 2. Docker Compose File

Add a `docker-compose.yml` file:

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    restart: always
```

## 3. GitHub Actions Workflow

Use the `deploy.docker.compose.yml` template from fastpull. The runner will automatically `docker compose up -d --build` on every push.
