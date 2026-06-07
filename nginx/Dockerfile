# services/nginx/Dockerfile - Nginx with explicit multi-platform support
FROM nginx:1.27-alpine

# Install curl for health checks
RUN apk add --no-cache \
    curl \
    bash \
    netcat-openbsd

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create web root if not exists
RUN mkdir -p /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health 2>/dev/null || exit 1

COPY scripts/wait-for-it.sh /wait-for-it.sh
RUN chmod 755 /wait-for-it.sh


# Expose HTTP port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
