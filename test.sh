#!/bin/bash
# Test Suite - balena-photo-cropper
# Validate cv2 installation + CakePHP + Nginx routing
# Run from project root directory

set -e

DEVICE_IP="${1:-localhost}"
DEVICE_UUID="${2:-none}"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     balena-photo-cropper - Validation Test Suite              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Testing against: $DEVICE_IP"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 1: Python CV2 Tests
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 SECTION 1: Python OpenCV Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test 1.1: Check cv2 import (local or via curl)"
echo "─────────────────────────────────────────────"
if command -v docker &> /dev/null && docker-compose ps cropper 2>/dev/null | grep -q "Up"; then
    echo "✓ Docker-compose detected, testing via docker exec"
    if docker exec cropper python3 -c "import cv2; print('OpenCV version:', cv2.__version__)" 2>/dev/null; then
        echo "✅ TEST PASSED: cv2 imports successfully"
    else
        echo "❌ TEST FAILED: cv2 import error"
        echo "   Running diagnostics..."
        docker exec cropper python3 -c "import sys; print('Python:', sys.version)"
        docker exec cropper apt list --installed | grep -i libpng || true
    fi
else
    echo "⚠️  Docker not available, testing via HTTP endpoint"
    # Assuming app.py has a /health endpoint
    if curl -s http://$DEVICE_IP:5000/health >/dev/null 2>&1; then
        echo "✅ Service responds to health check"
    else
        echo "❌ Service not responding"
    fi
fi
echo ""

echo "Test 1.2: Check system libraries"
echo "────────────────────────────────"
if command -v docker &> /dev/null && docker-compose ps cropper 2>/dev/null | grep -q "Up"; then
    LIBS=(libpng16-16 libjasper1 libtiff5 libwebp6)
    for lib in "${LIBS[@]}"; do
        if docker exec cropper dpkg -l | grep -q "^ii.*$lib"; then
            echo "✅ $lib installed"
        else
            echo "❌ $lib NOT FOUND"
        fi
    done
else
    echo "⚠️  Cannot check libraries without docker access"
fi
echo ""

echo "Test 1.3: Check Python requirements versions"
echo "─────────────────────────────────────────────"
if [ -f "services/cropper/requirements.txt" ]; then
    echo "Current requirements.txt:"
    cat services/cropper/requirements.txt
    echo ""
    echo "Recommended versions for armhf:"
    cat << 'REQS'
opencv-python==4.8.1.78
numpy==1.24.3
Pillow>=9.5.0
requests>=2.28.0
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=20.1.0
REQS
else
    echo "⚠️  requirements.txt not found at services/cropper/requirements.txt"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 2: CakePHP Tests
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 SECTION 2: CakePHP Installation Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test 2.1: CakePHP directory structure"
echo "─────────────────────────────────────"
CAKE_DIRS=(
    "services/web"
    "services/web/src"
    "services/web/src/Controller"
    "services/web/config"
    "services/web/vendor"
)

for dir in "${CAKE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir NOT FOUND"
    fi
done
echo ""

echo "Test 2.2: CakePHP key files"
echo "───────────────────────────"
CAKE_FILES=(
    "services/web/vendor/autoload.php"
    "services/web/config/bootstrap.php"
    "services/web/config/routes.php"
    "services/web/src/Controller/AppController.php"
)

for file in "${CAKE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file found"
    else
        echo "❌ $file NOT FOUND"
    fi
done
echo ""

echo "Test 2.3: CropperController.php"
echo "──────────────────────────────"
if [ -f "services/web/src/Controller/CropperController.php" ]; then
    echo "✅ CropperController.php found"
    echo ""
    echo "Functions in CropperController:"
    grep -n "public function" services/web/src/Controller/CropperController.php || echo "⚠️  No public functions found"
else
    echo "❌ CropperController.php NOT FOUND"
    echo "   Expected at: services/web/src/Controller/CropperController.php"
fi
echo ""

echo "Test 2.4: Routes configuration"
echo "──────────────────────────────"
if [ -f "services/web/config/routes.php" ]; then
    if grep -q "cropper" services/web/config/routes.php; then
        echo "✅ Cropper routes found in config/routes.php"
        echo ""
        echo "Cropper route definitions:"
        grep -A 3 "scope.*cropper" services/web/config/routes.php || true
    else
        echo "❌ No cropper routes in config/routes.php"
        echo "   Add this to config/routes.php:"
        cat << 'ROUTES'
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
});
$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
ROUTES
    fi
else
    echo "❌ config/routes.php NOT FOUND"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 3: Nginx Configuration Tests
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 SECTION 3: Nginx Configuration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Test 3.1: Nginx conf.d files"
echo "────────────────────────────"
if [ -f "services/nginx/conf.d/cropper.conf" ]; then
    echo "✅ services/nginx/conf.d/cropper.conf exists"
    echo ""
    echo "Upstream blocks:"
    grep -i "upstream" services/nginx/conf.d/cropper.conf
else
    echo "❌ services/nginx/conf.d/cropper.conf NOT FOUND"
    echo "   This file is REQUIRED for routing"
fi
echo ""

echo "Test 3.2: Nginx location blocks"
echo "───────────────────────────────"
if [ -f "services/nginx/conf.d/cropper.conf" ]; then
    echo "Location blocks in config:"
    grep -n "location" services/nginx/conf.d/cropper.conf
else
    echo "⚠️  Cannot check - file not found"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 4: HTTP Endpoint Tests
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 SECTION 4: HTTP Endpoint Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$DEVICE_IP" != "localhost" ]; then
    echo "Test 4.1: GET http://$DEVICE_IP/cropper.php"
    echo "──────────────────────────────────────────────"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DEVICE_IP/cropper.php || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ /cropper.php responds with 200"
    elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "❌ /cropper.php redirects (HTTP $HTTP_CODE)"
        echo "   This indicates routing not working"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️  Cannot reach $DEVICE_IP (connection error)"
    else
        echo "⚠️  /cropper.php responds with HTTP $HTTP_CODE"
    fi
    echo ""

    echo "Test 4.2: GET http://$DEVICE_IP/cropper"
    echo "───────────────────────────────────────"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DEVICE_IP/cropper || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ /cropper responds with 200"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️  Cannot reach $DEVICE_IP"
    else
        echo "⚠️  /cropper responds with HTTP $HTTP_CODE"
    fi
    echo ""

    echo "Test 4.3: Python service health"
    echo "───────────────────────────────"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DEVICE_IP:5000/health || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Python service (port 5000) responds"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "❌ Python service not responding (port 5000)"
    else
        echo "⚠️  Python service responds with HTTP $HTTP_CODE"
    fi
else
    echo "⚠️  DEVICE_IP is 'localhost' - skipping HTTP tests"
    echo "   To test against device, run:"
    echo "   $0 <device-ip>"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Review results above"
echo "2. Fix any ❌ items"
echo "3. Rebuild: docker-compose build --no-cache"
echo "4. Restart: docker-compose up -d"
echo "5. Re-run tests: bash test-validation.sh $DEVICE_IP"
echo ""
