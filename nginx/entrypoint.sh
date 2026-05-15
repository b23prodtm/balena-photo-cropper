#!/bin/sh
set -e

SSL_DIR="/etc/nginx/ssl"
mkdir -p "$SSL_DIR"

KEY="$SSL_DIR/server.key"
CRT="$SSL_DIR/server.crt"

echo "🔍 Checking for SSL material..."

# 1. Docker secrets
if [ -f /run/secrets/ssl_key ] && [ -f /run/secrets/ssl_crt ]; then
    echo "➡️ Using Docker secrets"
    cp /run/secrets/ssl_key "$KEY"
    cp /run/secrets/ssl_crt "$CRT"
fi

# 2. Mounted certs
if [ -f "$KEY" ] && [ -f "$CRT" ]; then
    echo "➡️ Using mounted SSL certificates"
    exec "$@"
fi

# 3. Environment variables
if [ -n "$SSL_KEY" ] && [ -n "$SSL_CRT" ]; then
    echo "➡️ Using SSL from environment variables"
    echo "$SSL_KEY" > "$KEY"
    echo "$SSL_CRT" > "$CRT"
    exec "$@"
fi

# 4. Runtime generation (fallback)
echo "⚠️ No SSL provided — generating ephemeral certificate..."
openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CRT" \
    -subj "/CN=localhost"

echo "✔️ Ephemeral certificate generated"

exec "$@"
