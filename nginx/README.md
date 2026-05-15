# Nginx HTTPS — Runtime SSL Generation with Secrets Support

This container provides an Nginx server with **automatic SSL certificate handling** at runtime.

It supports three modes:

1. **Docker secrets** (highest priority)  
2. **Environment variables** (`SSL_KEY`, `SSL_CRT`)  
3. **Ephemeral runtime certificate generation** (fallback)

This ensures secure deployments without baking private keys into the Docker image.

---

## 🔐 SSL Priority Order

At container startup, the entrypoint script checks for SSL material in this order:

1. **Docker secrets**  
   - `/run/secrets/ssl_key`  
   - `/run/secrets/ssl_crt`

2. **Environment variables**  
   - `SSL_KEY`  
   - `SSL_CRT`

3. **Auto‑generation**  
   - Creates a 2048‑bit RSA key  
   - Generates a self‑signed certificate valid for 1 year  
   - CN = `localhost`

---

## 📁 File Structure

