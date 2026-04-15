# ============================================================
# Multi-stage Dockerfile for JBrowse 2 web app
# ============================================================

# ----------------------------------------------------------
# Stage 1: Build JBrowse 2
# ----------------------------------------------------------
FROM node:20-slim AS builder

RUN npm install -g @jbrowse/cli

RUN jbrowse create /jbrowse

# ----------------------------------------------------------
# Stage 2: Serve with nginx
# ----------------------------------------------------------
FROM nginx:alpine

# Install jbrowse CLI for entrypoint configuration
RUN apk add --no-cache nodejs npm && \
    npm install -g @jbrowse/cli

# Copy JBrowse app
COPY --from=builder /jbrowse /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
