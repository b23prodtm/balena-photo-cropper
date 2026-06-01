# Diagnostic et Fixes - balena-photo-cropper

## 🔍 ANALYSE DE TON PROBLÈME

**Status actuel:**
- ✅ Nginx fonctionne bien
- ✅ PHP-FPM fonctionne bien
- ❌ ImportError cv2 : `libpng16.so.16: cannot open shared object file`
- ❌ Besoin de vérifier CakePHP installation
- ❌ Besoin de vérifier accès `/cropper.php`

---

## 🧪 DIAGNOSTIC 1 : Vérifier CakePHP Installation

### **Test 1.1 : Fichiers CakePHP présents ?**

```bash
# SSH dans le service web
balena ssh <device-uuid> -s web

# Vérifier structure CakePHP
ls -la /var/www/html/
ls -la /var/www/html/vendor/cakephp/cakephp/ 2>/dev/null || echo "CakePHP pas trouvé!"

# Vérifier composer autoload
test -f /var/www/html/vendor/autoload.php && echo "✅ Autoloader CakePHP OK" || echo "❌ Autoloader manquant"
```

**Expected Output:**
```
total XX
drwxr-xr-x  app
drwxr-xr-x  bin
drwxr-xr-x  config
drwxr-xr-x  logs
drwxr-xr-x  plugins
drwxr-xr-x  src
drwxr-xr-x  tests
drwxr-xr-x  tmp
drwxr-xr-x  webroot
drwxr-xr-x  vendor
-rw-r--r--  .env
-rw-r--r--  index.php
✅ Autoloader CakePHP OK
```

---

### **Test 1.2 : Configuration CakePHP correcte ?**

```bash
# Vérifier config/routes.php
cat /var/www/html/config/routes.php | head -30

# Vérifier config/app.php
grep -i "debug\|security\|database" /var/www/html/config/app.php | head -10

# Vérifier logs pour erreurs
tail -50 /var/www/html/logs/error.log 2>/dev/null || echo "Pas de logs d'erreur"
tail -50 /var/www/html/logs/debug.log 2>/dev/null || echo "Pas de logs debug"
```

**Signs d'erreurs:** 
- `Missing connection config "default"`
- `Can't load Router`
- `Permission denied` sur fichiers

---

### **Test 1.3 : PHP-FPM peut atteindre l'appli ?**

```bash
# Tester depuis PHP-FPM
docker exec web php -r "
define('DS', DIRECTORY_SEPARATOR);
define('ROOT', dirname(__FILE__));
define('APP_DIR', 'app');
require 'vendor/autoload.php';
require 'config/bootstrap.php';
echo 'CakePHP OK';
"
```

**Expected:** `CakePHP OK`

---

### **Test 1.4 : Controller Cropper existe ?**

```bash
ls -la /var/www/html/src/Controller/CropperController.php

# Vérifier contenu
grep -n "public function" /var/www/html/src/Controller/CropperController.php
```

**Expected:**
```
-rw-r--r-- 1 www-data www-data XXXX CropperController.php

    public function index()
    public function crop()
    public function upload()
```

---

## 🧪 DIAGNOSTIC 2 : Vérifier Accès `/cropper.php`

### **Test 2.1 : Route configurée ?**

```bash
# Vérifier que route est enregistrée
grep -n "cropper" /var/www/html/config/routes.php

# Vérifier que routes.php n'a pas d'erreur syntaxe PHP
php -l /var/www/html/config/routes.php
```

**Expected:**
```
config/routes.php: No syntax errors
```

---

### **Test 2.2 : Accès HTTP `/cropper.php`**

```bash
# Depuis host (ou autre device)
curl -i http://<device-ip>/cropper.php

# Vérifier headers (important!)
curl -i -H "Host: localhost" http://<device-ip>/cropper.php

# Vérifier dans logs nginx
docker logs nginx | grep -A 5 "cropper.php"
```

**Expected:**
- Status 200 (pas 301)
- Response contient du HTML CakePHP
- Logs nginx montrent pas d'erreur

---

### **Test 2.3 : Accès HTTP `/cropper`**

```bash
curl -i http://<device-ip>/cropper
curl -i http://<device-ip>/cropper/
```

**Expected:** 200 OK + interface HTML

---

## 🔧 FIX 1 : Python cv2 ImportError

### **ROOT CAUSE**
Le service `cropper` essaie d'importer cv2 mais les libs système manquent.

### **SOLUTION - Modifier services/cropper/Dockerfile**

```dockerfile
FROM balena/rpi-python:3.11

# ← AJOUTER CES LIGNES AVANT pip install

# Install system dependencies for OpenCV on armhf
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    libharfbuzz0b \
    libwebpmux3 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libxkbcommon0 \
    python3-pip \
    python3-dev \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

# Install Python packages WITH compatible versions for armhf
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY . .

CMD ["python3", "app.py"]
```

### **SOLUTION - Remplacer services/cropper/requirements.txt**

```txt
# Python requirements for armhf (Raspberry Pi)
opencv-python==4.8.1.78
numpy==1.24.3
Pillow>=9.5.0
requests>=2.28.0
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=20.1.0
```

**Important:** Ne pas utiliser `opencv-python-headless` si tu besoin de GUI

---

### **SOLUTION - Test rapide cv2 fix**

```bash
# Rebuild sans cache
docker-compose build --no-cache cropper

# Test import
docker-compose up cropper

# Vérifier logs
docker logs <cropper-container-id> | grep -i "import\|error"
```

**Expected:** Pas d'ImportError

---

## 🔧 FIX 2 : CakePHP Configuration

### **Si CakePHP n'est pas encore installé :**

```bash
# SSH dans web service
balena ssh <device-uuid> -s web

# Installer via composer
cd /var/www/html
composer require cakephp/cakephp:~4.4.0

# OU si structure CakePHP existe déjà
composer update
```

### **Si besoin de CropperController :**

```bash
# Créer le répertoire s'il n'existe pas
mkdir -p /var/www/html/src/Controller

# Copier le CropperController.php (voir Package PR)
cp CropperController.php /var/www/html/src/Controller/

# Vérifier permissions
chown www-data:www-data /var/www/html/src/Controller/CropperController.php
chmod 644 /var/www/html/src/Controller/CropperController.php
```

---

### **Si routes ne sont pas configurées :**

Ajouter à `/var/www/html/config/routes.php` AVANT le `fallbacks()`:

```php
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
});

$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
```

---

## 🔧 FIX 3 : Nginx Configuration

### **Vérifier /etc/nginx/conf.d/cropper.conf existe**

```bash
docker exec nginx ls -la /etc/nginx/conf.d/
```

**Si manquant, créer le fichier :**

```bash
# Créer depuis host
cat > services/nginx/conf.d/cropper.conf << 'EOF'
upstream cropper_service {
    server cropper:5000;
}

upstream web_service {
    server web:9000;
}

server {
    listen 80 default_server;
    server_name _;
    
    root /var/www/html;
    index index.php index.html index.htm;

    location = / {
        try_files $uri /index.php?$query_string;
    }

    location = /cropper.php {
        try_files $uri /index.php?$query_string;
    }

    location ~ ^/cropper/api {
        proxy_pass http://cropper_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /cropper {
        try_files $uri @cropper_cake;
    }

    location @cropper_cake {
        rewrite ^ /index.php?$request_uri break;
        fastcgi_pass web_service;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        include fastcgi_params;
    }

    location ~ \.php$ {
        fastcgi_pass web_service;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

# Rebuild nginx
docker-compose build nginx
docker-compose up -d nginx
```

---

## ✅ CHECKLIST COMPLÈTE

### **Avant de démarrer**

- [ ] J'ai les fichiers du package PR
- [ ] Je sais où SSH sur Balena device
- [ ] J'ai curl ou wget pour tester HTTP

### **Phase 1 : Diagnostic**

- [ ] Test 1.1 : CakePHP fichiers présents
- [ ] Test 1.2 : Configuration CakePHP OK
- [ ] Test 1.3 : PHP-FPM peut charger CakePHP
- [ ] Test 1.4 : CropperController.php existe
- [ ] Test 2.1 : Routes configurées
- [ ] Test 2.2 : `/cropper.php` accessible
- [ ] Test 2.3 : `/cropper` accessible

### **Phase 2 : Fixes**

- [ ] Fix 1 : Dockerfile cropper updated (libpng16 etc)
- [ ] Fix 1 : requirements.txt updated (versions pinnées)
- [ ] Fix 2 : CakePHP installé/configured
- [ ] Fix 2 : CropperController.php placé correctement
- [ ] Fix 2 : routes.php contient les routes cropper
- [ ] Fix 3 : nginx conf/cropper.conf créé/configuré

### **Phase 3 : Validation**

- [ ] `docker-compose build` passe sans erreur
- [ ] Services démarrent : `docker-compose up -d`
- [ ] `docker logs cropper` : pas d'ImportError cv2
- [ ] `curl http://localhost/cropper.php` → 200 OK
- [ ] `curl http://localhost/cropper` → 200 OK + HTML
- [ ] Nginx logs propres (pas d'erreur)
- [ ] PHP-FPM logs propres (pas d'erreur)

---

## 📞 TROUBLESHOOTING AVANCÉ

### **Si ImportError persiste après rebuild**

```bash
# Force rebuild sans cache
docker-compose build --no-cache cropper

# Vérifier les libs sont bien installées
docker exec cropper apt list --installed | grep -i "libpng\|libjasper"

# Test direct import depuis container
docker exec cropper python3 -c "import cv2; print(cv2.__version__)"
```

---

### **Si /cropper.php retourne 301**

```bash
# Vérifier Nginx routing
docker exec nginx grep -A 10 "cropper.php" /etc/nginx/conf.d/cropper.conf

# Vérifier CakePHP routes
docker exec web cat /var/www/html/config/routes.php | grep -A 5 "cropper"

# Vérifier rewrite est appliqué
curl -i http://localhost/cropper.php 2>&1 | head -20
```

---

### **Si CropperController génère erreur 500**

```bash
# Vérifier error logs
docker exec web tail -100 /var/www/html/logs/error.log

# Vérifier syntax PHP du controller
docker exec web php -l /var/www/html/src/Controller/CropperController.php

# Vérifier permissions fichiers
docker exec web ls -la /var/www/html/src/Controller/
```

---

## 🎯 RÉSUMÉ DES ACTIONS

1. **Diagnostic** → Tests 1.1 à 2.3 pour identifier exactement le problème
2. **Fix cv2** → Dockerfile + requirements.txt (PRIORITAIRE)
3. **Fix CakePHP** → Installation/configuration si nécessaire
4. **Fix Nginx** → Routing configuration cropper.conf
5. **Validation** → Tous les tests passent ✅

**Temps estimé :** 30-45 minutes

---

**Créé par :** Claude  
**Date :** 2026-05-15  
**Status :** 🔧 Diagnostic Ready
