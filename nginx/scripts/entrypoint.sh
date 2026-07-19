#!/bin/bash
set -e

# ============================================================================
# NGINX ENTRYPOINT - SSL Certificate Handling at Runtime
# ============================================================================
# Priority order for SSL certificates:
# 1. Docker secrets (/run/secrets/SSL_KEY and /run/secrets/SSL_CRT)
# 2. Environment variables (SSL_KEY_FILE and SSL_CRT_FILE)
# 3. Existing certificates in /etc/nginx/ssl/
# 4. Auto-generate self-signed certificate
# ============================================================================

SSL_DIR="/etc/nginx/ssl"
SSL_KEY="${SSL_DIR}/server.key"
SSL_CRT="${SSL_DIR}/server.crt"

echo "=== Nginx SSL Certificate Handler ==="
echo "SSL Directory: ${SSL_DIR}"

# Create SSL directory if it doesn't exist
mkdir -p "${SSL_DIR}"
chmod 700 "${SSL_DIR}"

# Function to check if cert is valid
check_cert_valid() {
    local cert_file="$1"
    if [ ! -f "$cert_file" ]; then
        return 1
    fi
    # Check if cert will be valid for at least 1 day
    openssl x509 -in "$cert_file" -noout -checkend 86400 >/dev/null 2>&1
    return $?
}

# ============================================================================
# PRIORITY 1: Docker Secrets (highest priority)
# ============================================================================
if [ -f /run/secrets/SSL_KEY ] && [ -f /run/secrets/SSL_CRT ]; then
    echo "✅ Found Docker secrets: SSL_KEY and SSL_CRT"
    cp /run/secrets/SSL_KEY "${SSL_KEY}"
    cp /run/secrets/SSL_CRT "${SSL_CRT}"
    chmod 600 "${SSL_KEY}"
    chmod 644 "${SSL_CRT}"
    echo "✅ Certificates installed from Docker secrets"
    openssl x509 -in "${SSL_CRT}" -noout -dates
    
# ============================================================================
# PRIORITY 2: Environment Variables (SSL_KEY_FILE and SSL_CRT_FILE)
# ============================================================================
elif [ -n "${SSL_KEY_FILE:-}" ] && [ -n "${SSL_CRT_FILE:-}" ]; then
    if [ -f "${SSL_KEY_FILE}" ] && [ -f "${SSL_CRT_FILE}" ]; then
        echo "✅ Found environment variable certificates: ${SSL_KEY_FILE} and ${SSL_CRT_FILE}"
        cp "${SSL_KEY_FILE}" "${SSL_KEY}"
        cp "${SSL_CRT_FILE}" "${SSL_CRT}"
        chmod 600 "${SSL_KEY}"
        chmod 644 "${SSL_CRT}"
        echo "✅ Certificates installed from environment variables"
        openssl x509 -in "${SSL_CRT}" -noout -dates
    else
        echo "⚠️  Environment variables set but files not found, falling back..."
        NEED_CERT=1
    fi
    
# ============================================================================
# PRIORITY 3: Check for existing valid certificates
# ============================================================================
elif [ -f "${SSL_KEY}" ] && [ -f "${SSL_CRT}" ]; then
    if check_cert_valid "${SSL_CRT}"; then
        echo "✅ Existing certificates found and valid"
        openssl x509 -in "${SSL_CRT}" -noout -dates
    else
        echo "⚠️  Existing certificates found but expired, regenerating..."
        NEED_CERT=1
    fi
else
    echo "ℹ️  No existing certificates found, generating new ones..."
    NEED_CERT=1
fi

# ============================================================================
# PRIORITY 4: Auto-generate self-signed certificate (fallback)
# ============================================================================
if [ "${NEED_CERT:-0}" = "1" ]; then
    echo "🔄 Generating self-signed certificate..."
    openssl req -x509 \
        -newkey rsa:2048 \
        -keyout "${SSL_KEY}" \
        -out "${SSL_CRT}" \
        -days 365 \
        -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1"
    
    chmod 600 "${SSL_KEY}"
    chmod 644 "${SSL_CRT}"
    echo "✅ Self-signed certificate generated successfully"
    openssl x509 -in "${SSL_CRT}" -noout -dates
fi

echo ""
echo "=== SSL Certificate Details ==="
openssl x509 -in "${SSL_CRT}" -noout -text | grep -E "Subject:|Issuer:|Not Before|Not After|Public-Key:|CN=|DNS:"
echo ""

# ============================================================================
# Verify nginx configuration
# ============================================================================
echo "=== Validating Nginx Configuration ==="
if ! nginx -t; then
    echo "❌ Nginx configuration validation failed!"
    exit 1
fi
echo "✅ Nginx configuration is valid"

echo ""
echo "=== Starting Nginx ==="
# Execute nginx with the provided arguments (or default)
exec nginx -g "daemon off;" "$@"
