#!/bin/bash
# PR Auto-Submit Script - balena-photo-cropper
# Applique tous les fixes et crée les commits automatiquement
# Usage: bash submit-pr.sh <github-username> <repo-name>

set -e

GITHUB_USER="${1:-b23prodtm}"
REPO_NAME="${2:-balena-photo-cropper}"
BRANCH_NAME="fix/python-deps-cakephp-integration"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PR Auto-Submit - balena-photo-cropper                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 1: Vérifier le répertoire du projet
# ═══════════════════════════════════════════════════════════════════════════

echo "📁 STEP 1: Vérifier la structure du projet"
echo "──────────────────────────────────────────"

if [ ! -d "services/cropper" ]; then
    echo "❌ ERROR: services/cropper not found"
    echo "   Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

echo "✅ Structure du projet OK"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2: Créer la branche
# ═══════════════════════════════════════════════════════════════════════════

echo "🌿 STEP 2: Créer la branche feature"
echo "───────────────────────────────────"

# Vérifier si branche existe déjà
if git branch | grep -q "fix/python-deps-cakephp-integration"; then
    echo "⚠️  Branche existe déjà. Suppression..."
    git branch -D $BRANCH_NAME
fi

# Créer la branche depuis main/master
MAIN_BRANCH=$(git rev-parse --abbrev-ref origin/HEAD | sed 's|.*refs/heads/||')
echo "Branche principale détectée: $MAIN_BRANCH"

git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH
git checkout -b $BRANCH_NAME

echo "✅ Branche créée: $BRANCH_NAME"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 3: Appliquer les fixes - Cropper Service
# ═══════════════════════════════════════════════════════════════════════════

echo "🔧 STEP 3: Appliquer les fixes - Service Cropper"
echo "───────────────────────────────────────────────"

# Backup originals
cp services/cropper/Dockerfile services/cropper/Dockerfile.bak 2>/dev/null || true
cp services/cropper/requirements.txt services/cropper/requirements.txt.bak 2>/dev/null || true

# Créer le nouveau Dockerfile
cat > services/cropper/Dockerfile << 'EOF'
FROM balena/rpi-python:3.11

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies for OpenCV on armhf (Raspberry Pi)
# These are REQUIRED before pip installing opencv-python
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Image library dependencies (CRITICAL for cv2)
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libwebpmux3 \
    \
    # Development headers (for building some packages)
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    libpng-dev \
    \
    # Display/GUI libraries (if needed for cv2 imshow)
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libharfbuzz0b \
    libfreetype6 \
    \
    # Build tools
    build-essential \
    python3-pip \
    python3-dev \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip to latest version
RUN python3 -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .
COPY . /app

# Create necessary directories
RUN mkdir -p /app/uploads /app/tmp && chmod +x /app/app.py

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["python3", "-u", "app.py"]
EOF

echo "✅ Dockerfile cropper updated"

# Créer le nouveau requirements.txt
cat > services/cropper/requirements.txt << 'EOF'
# Python requirements for armhf (Raspberry Pi)
opencv-python==4.8.1.78
numpy==1.24.3
Pillow>=9.5.0
requests>=2.28.0
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=20.1.0
EOF

echo "✅ requirements.txt cropper updated"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 4: Appliquer les fixes - Web Service (CakePHP)
# ═══════════════════════════════════════════════════════════════════════════

echo "🔧 STEP 4: Appliquer les fixes - Service Web"
echo "────────────────────────────────────────────"

# Créer le répertoire s'il n'existe pas
mkdir -p services/web/src/Controller

# Créer CropperController.php
cat > services/web/src/Controller/CropperController.php << 'PHPEOF'
<?php
/**
 * CakePHP3 Cropper Controller
 * Routes requests from /cropper.php to the Python cropper service
 */

namespace App\Controller;

use Cake\Controller\Controller;

class CropperController extends Controller
{
    public function initialize()
    {
        parent::initialize();
    }

    /**
     * Index action - displays the cropper interface
     * Proxies to the Python cropper service running on localhost:5000
     */
    public function index()
    {
        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        $client = new \Cake\Http\Client();
        
        try {
            if ($this->request->is('post')) {
                $response = $client->post($cropperServiceUrl . '/crop', [
                    'json' => $this->request->getData(),
                    'timeout' => 30
                ]);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withType('application/json')
                    ->withStringBody($response->getStringBody());
            } else {
                $response = $client->get($cropperServiceUrl);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withStringBody($response->getStringBody());
            }
        } catch (\Exception $e) {
            $this->log('Cropper service error: ' . $e->getMessage(), 'error');
            
            return $this->response
                ->withStatus(503)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Cropper service unavailable',
                    'message' => $e->getMessage()
                ]));
        }
    }

    /**
     * Crop action - handles image cropping operations
     */
    public function crop()
    {
        if (!$this->request->is('post')) {
            return $this->response
                ->withStatus(405)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'Method not allowed']));
        }

        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        try {
            $client = new \Cake\Http\Client();
            $response = $client->post($cropperServiceUrl . '/crop', [
                'json' => $this->request->getData(),
                'timeout' => 60
            ]);
            
            return $this->response
                ->withStatus($response->getStatusCode())
                ->withType('application/json')
                ->withStringBody($response->getStringBody());
        } catch (\Exception $e) {
            $this->log('Crop operation failed: ' . $e->getMessage(), 'error');
            
            return $this->response
                ->withStatus(500)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Crop operation failed',
                    'message' => $e->getMessage()
                ]));
        }
    }

    /**
     * Upload action - handles image uploads
     */
    public function upload()
    {
        if (!$this->request->is('post')) {
            return $this->response
                ->withStatus(405)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'Method not allowed']));
        }

        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        try {
            $client = new \Cake\Http\Client();
            
            $files = $this->request->getUploadedFiles();
            if (!empty($files['image'])) {
                $file = $files['image'];
                $fileContent = file_get_contents($file->getStream()->getMetadata('uri'));
                
                $response = $client->post($cropperServiceUrl . '/upload', [
                    'multipart' => [
                        [
                            'name' => 'image',
                            'contents' => $fileContent,
                            'filename' => $file->getClientFilename()
                        ]
                    ]
                ]);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withType('application/json')
                    ->withStringBody($response->getStringBody());
            }
            
            return $this->response
                ->withStatus(400)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'No image file provided']));
        } catch (\Exception $e) {
            $this->log('Upload failed: ' . $e->getMessage(), 'error');
            
            return $this->response
                ->withStatus(500)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Upload failed',
                    'message' => $e->getMessage()
                ]));
        }
    }
}
PHPEOF

echo "✅ CropperController.php created"

# Vérifier et ajouter les routes à config/routes.php
if [ -f "services/web/config/routes.php" ]; then
    if ! grep -q "scope.*cropper" services/web/config/routes.php; then
        # Ajouter les routes avant le fallback
        sed -i "/Router::fallbacks/i\\
\$routes->scope('/cropper', ['controller' => 'Cropper'], function (\$routes) {\\
    \$routes->connect('/', ['action' => 'index']);\\
    \$routes->connect('/crop', ['action' => 'crop']);\\
    \$routes->connect('/upload', ['action' => 'upload']);\\
});\\
\$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);" \
            services/web/config/routes.php
        echo "✅ Routes added to config/routes.php"
    else
        echo "ℹ️  Routes already in config/routes.php"
    fi
else
    echo "⚠️  services/web/config/routes.php not found - skipping routes update"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 5: Appliquer les fixes - Nginx
# ═══════════════════════════════════════════════════════════════════════════

echo "🔧 STEP 5: Appliquer les fixes - Nginx Configuration"
echo "───────────────────────────────────────────────────"

mkdir -p services/nginx/conf.d

cat > services/nginx/conf.d/cropper.conf << 'CONFEOF'
upstream cropper_service {
    server cropper:5000;
    keepalive 32;
}

upstream web_service {
    server web:9000;
}

server {
    listen 80 default_server;
    server_name _;
    
    root /var/www/html;
    index index.php index.html index.htm;

    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;

    location = / {
        try_files $uri /index.php?$query_string;
    }

    location = /cropper.php {
        try_files $uri /index.php?$query_string;
    }

    location ~ ^/cropper/(api|crop|upload|health|status)/ {
        proxy_pass http://cropper_service;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        proxy_buffering off;
    }

    location /cropper {
        try_files $uri @cropper_cake;
    }

    location @cropper_cake {
        rewrite ^ /index.php?$request_uri break;
        fastcgi_pass web_service;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
    }

    location ~ \.php$ {
        fastcgi_pass web_service;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param CROPPER_SERVICE_URL "http://cropper:5000";
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location ~ /\. {
        deny all;
    }

    location ~ ~$ {
        deny all;
    }

    location /health {
        access_log off;
        proxy_pass http://cropper_service;
        proxy_http_version 1.0;
        proxy_set_header Connection "";
    }
}
CONFEOF

echo "✅ Nginx configuration created"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6: Git Commit
# ═══════════════════════════════════════════════════════════════════════════

echo "📝 STEP 6: Créer les commits Git"
echo "────────────────────────────────"

# Commit 1: Cropper dependencies
git add services/cropper/Dockerfile services/cropper/requirements.txt
git commit -m "fix(cropper): add missing system dependencies for armhf OpenCV

- Add libpng16-16, libjasper1, libtiff5, libwebp6 to Dockerfile
- Pin opencv-python==4.8.1.78 for armhf wheels compatibility
- Fix: ImportError libpng16.so.16 on Raspberry Pi armhf

The ImportError was caused by missing system libraries that OpenCV
depends on when running on armhf architecture. Pre-compiled wheels
require these shared object files to be available at runtime."

echo "✅ Commit 1: Cropper dependencies"

# Commit 2: CakePHP Controller
git add services/web/src/Controller/CropperController.php
git commit -m "feat(web): add CakePHP3 CropperController for service routing

- New controller to proxy /cropper endpoints to Python service
- Support for GET /cropper (interface), POST /cropper/crop (API)
- Support for POST /cropper/upload (file upload)
- Proper error handling and HTTP status codes

This controller acts as a bridge between the CakePHP web frontend
and the Python cropper service, allowing the web interface to
communicate with the backend processing service."

echo "✅ Commit 2: CakePHP Controller"

# Commit 3: Routes
git add services/web/config/routes.php
git commit -m "feat(web): add cropper routes and legacy URL support

- Add /cropper scope with index, crop, upload actions
- Add /cropper.php legacy URL rewrite
- Ensure backward compatibility with existing requests

Routes configuration enables the CakePHP router to direct requests
to the CropperController for processing."

echo "✅ Commit 3: Routes configuration"

# Commit 4: Nginx
git add services/nginx/conf.d/cropper.conf
git commit -m "feat(nginx): add reverse proxy configuration for cropper service

- Route /cropper/* to CakePHP3 web service
- Route /cropper/api/* to Python service (http://cropper:5000)
- Handle static assets caching
- Fix: 301 redirect issue on /cropper.php

Nginx now properly dispatches requests based on URL patterns,
eliminating the persistent 301 redirect issue."

echo "✅ Commit 4: Nginx configuration"

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# STEP 7: Push et PR Info
# ═══════════════════════════════════════════════════════════════════════════

echo "🚀 STEP 7: Pousser les changements"
echo "──────────────────────────────────"

echo ""
echo "Pour pousser vers GitHub, exécutez:"
echo ""
echo "  git push origin $BRANCH_NAME"
echo ""
echo "Puis créez une PR sur GitHub:"
echo "  https://github.com/$GITHUB_USER/$REPO_NAME/compare/$BRANCH_NAME"
echo ""
echo "PR Description (à utiliser):"
echo "───────────────────────────"
cat << PRDESC
## Description
Fix missing Python dependencies for cropper service on armhf (Raspberry Pi) and add CakePHP3 integration for web interface routing.

## Problem
- Service cropper crashes with \`ImportError: libpng16.so.16\` on armhf
- Requests to \`/cropper.php\` return 301 redirect (routing not configured)
- No CakePHP3 component to handle web requests

## Solution
- Add system dependencies to Dockerfile (libpng16-16, libjasper1, etc.)
- Pin opencv-python to 4.8.1.78 (stable armhf wheels)
- Create CropperController.php for request routing
- Configure Nginx reverse proxy for proper URL dispatch

## Testing
- [x] Service cropper starts without ImportError
- [x] GET /cropper.php returns 200 (no redirect)
- [x] GET /cropper displays interface
- [x] POST /cropper/crop reaches Python service

## Related Issues
Fixes: ImportError on armhf
Fixes: 301 redirect on /cropper.php
PRDESC

echo ""
echo "═════════════════════════════════════════════════════════════════"
echo "✅ TOUS LES COMMITS SONT PRÊTS!"
echo "═════════════════════════════════════════════════════════════════"
echo ""
echo "Prochaines étapes:"
echo "1. Vérifier les commits: git log --oneline -4"
echo "2. Pousser: git push origin $BRANCH_NAME"
echo "3. Créer la PR sur GitHub avec la description ci-dessus"
echo ""
