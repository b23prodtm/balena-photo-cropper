# services/nginx/Dockerfile - Image Nginx officielle Docker Hub (pas Balena)

FROM nginx:latest

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy custom nginx configuration
COPY conf.d/ /etc/nginx/conf.d/
COPY nginx.conf /etc/nginx/nginx.conf

# Create web root if not exists
RUN mkdir -p /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health 2>/dev/null || exit 1

# Expose HTTP port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]