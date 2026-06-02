FROM nginx:latest
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
 
COPY conf.d/ /etc/nginx/conf.d/
COPY nginx.conf /etc/nginx/nginx.conf 2>/dev/null || true
 
RUN mkdir -p /var/www/html
 
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health 2>/dev/null || exit 1
 
EXPOSE 80
 
CMD ["nginx", "-g", "daemon off;"]
