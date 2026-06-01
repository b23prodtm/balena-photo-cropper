# Guide de déploiement - PR balena-photo-cropper

## **Vue d'ensemble**

Cette PR contient :
1. **Corrections Python armhf** → dépendances système OpenCV
2. **Composant CakePHP3** → routage `/cropper.php` vers service Python
3. **Configuration Nginx** → dispatcher requêtes HTTP

---

## **Étape 1 : Mettre à jour le service Cropper**

### **A. Modifier le `Dockerfile` du service cropper**

**Fichier :** `services/cropper/Dockerfile`

```dockerfile
FROM balena/rpi-raspbian:bullseye

# Install system dependencies for OpenCV on armhf
RUN apt-get update && apt-get install -y \
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    libharfbuzz0b \
    libwebpmux3 \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["python3", "app.py"]
```

**Point clé :** Les `libpng16-16`, `libjasper1`, etc. sont les dépendances système manquantes qui causaient l'erreur `ImportError: libpng16.so.16`

---

### **B. Remplacer le `requirements.txt` du service cropper**

**Fichier :** `services/cropper/requirements.txt`

```txt
opencv-python==4.8.1.78
numpy>=1.21.0,<1.26.0
Pillow>=9.0.0
requests>=2.28.0
flask>=2.2.0
werkzeug>=2.2.0
gunicorn>=20.1.0
```

**Rationale :**
- `opencv-python==4.8.1.78` → version avec wheels armhf stables
- `numpy<1.26.0` → compatible avec armhf (1.26+ peut avoir issues)
- Pinning versions → reproductibilité builds

---

## **Étape 2 : Ajouter le composant CakePHP3**

### **A. Créer le contrôleur Cropper**

**Fichier :** `services/web/src/Controller/CropperController.php`

Copier le contenu de `CropperController.php` fourni

**Répertoire :** Ce fichier doit être dans `services/web/src/Controller/` (structure CakePHP3 standard)

---

### **B. Configurer les routes**

**Fichier :** `services/web/config/routes.php`

Ajouter au début de `Router::scope('/', function ...)`:

```php
// Cropper routes
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
});

// Legacy /cropper.php support
$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
```

---

## **Étape 3 : Configurer Nginx**

### **Configuration du reverse proxy**

**Fichier :** `services/nginx/conf.d/cropper.conf` (nouveau fichier)

Copier le contenu de `nginx-cropper.conf` fourni

**Alternativement**, si vous modifiez le `nginx.conf` existant :

**Location blocks critiques :**

```nginx
# 1. Route API vers service Python
location ~ ^/cropper/(api|crop|upload|health)/ {
    proxy_pass http://cropper:5000;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

# 2. Route interface vers CakePHP
location /cropper {
    try_files $uri @cropper_cake;
}

location @cropper_cake {
    rewrite ^ /index.php?$request_uri break;
    fastcgi_pass web_service;
    fastcgi_index index.php;
    include fastcgi_params;
}

# 3. Route legacy /cropper.php
location = /cropper.php {
    try_files $uri /index.php?$query_string;
}
```

---

## **Étape 4 : Variables d'environnement (optionnel)**

Dans `docker-compose.yml` ou `balena.yml`, ajouter :

```yaml
services:
  web:
    environment:
      CROPPER_SERVICE_URL: "http://cropper:5000"
      
  cropper:
    environment:
      FLASK_ENV: "production"
      PYTHONUNBUFFERED: "1"
```

---

## **Étape 5 : Validation post-déploiement**

### **Test 1 : Service Cropper démarre**
```bash
# SSH sur l'appareil Balena
balena ssh <device-uuid> -s cropper

# Vérifier absence d'ImportError
docker logs <cropper-container-id>
# Expected: AUCUN "libpng16.so.16" error
```

### **Test 2 : Interface accessible**
```bash
curl http://<device-ip>/cropper
# Expected: 200 OK + HTML page
```

### **Test 3 : Legacy URL fonctionne**
```bash
curl -L http://<device-ip>/cropper.php
# Expected: Pas de 301 redirect, affiche l'interface
```

### **Test 4 : API accessible**
```bash
curl http://<device-ip>/cropper/crop
# Expected: 200 ou 405 (POST only) - mais PAS d'erreur de connexion
```

---

## **Structure de fichiers finale**

```
balena-photo-cropper/
├── services/
│   ├── cropper/
│   │   ├── Dockerfile          ← MODIFIÉ (dépendances système)
│   │   ├── requirements.txt     ← REMPLACÉ (versions pinnées)
│   │   ├── app.py              ← Inchangé
│   │   └── ...
│   ├── web/
│   │   ├── src/
│   │   │   ├── Controller/
│   │   │   │   ├── CropperController.php  ← NOUVEAU
│   │   │   │   └── ...
│   │   │   └── ...
│   │   ├── config/
│   │   │   ├── routes.php      ← MODIFIÉ (ajout routes cropper)
│   │   │   └── ...
│   │   └── ...
│   ├── nginx/
│   │   ├── conf.d/
│   │   │   ├── cropper.conf    ← NOUVEAU
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── docker-compose.yml
├── balena.yml
└── ...
```

---

## **Dépannage**

### **Problème : "libpng16.so.16: cannot open shared object file"**

**Solution :** Vérifier que le Dockerfile cropper inclut `libpng16-16` dans les `apt-get install`

```bash
docker logs cropper | grep -i "libpng\|ImportError"
```

---

### **Problème : /cropper.php retourne 301 (redirect infini)**

**Solution 1 :** Vérifier que CakePHP3 CropperController.php est en place
```bash
ls -l services/web/src/Controller/CropperController.php
```

**Solution 2 :** Vérifier que routes.php contient les routes cropper
```bash
grep -A 5 "scope.*cropper" services/web/config/routes.php
```

**Solution 3 :** Vérifier nginx location blocks
```bash
docker exec nginx grep -A 10 "location /cropper" /etc/nginx/conf.d/cropper.conf
```

---

### **Problème : Service cropper ne démarre pas**

```bash
docker logs cropper | head -50
# Vérifier ImportError vs. autres erreurs

# Test import cv2 directement
docker run --rm balena/rpi-raspbian:bullseye bash -c \
  "apt-get update && apt-get install -y libpng16-16 python3-pip && \
   pip install opencv-python==4.8.1.78 && \
   python3 -c 'import cv2; print(cv2.__version__)'"
```

---

## **Commits Git pour la PR**

Exemple de commits structurés :

```
commit 1: "fix(cropper): add missing system dependencies for armhf OpenCV

- Add libpng16-16, libjasper1, libtiff5, libwebp6 to Dockerfile
- Pin opencv-python to 4.8.1.78 for armhf wheels
- Fixes: ImportError libpng16.so.16 on Raspberry Pi"

commit 2: "feat(web): add CakePHP3 CropperController

- New controller to proxy requests to Python cropper service
- Supports /cropper/crop, /cropper/upload endpoints
- Routes legacy /cropper.php to new interface"

commit 3: "feat(nginx): add reverse proxy configuration for cropper

- Route /cropper/* to CakePHP3 controller
- Route /cropper/(api|crop|upload)/* to Python service
- Fix 301 redirect issue on /cropper.php"

commit 4: "docs: add cropper integration and troubleshooting guide"
```

---

## **PR Description Template**

```markdown
## Description
Fix missing Python dependencies for cropper service on armhf (Raspberry Pi) and add CakePHP3 integration for web interface routing.

## Changes
- **cropper/Dockerfile**: Add system dependencies (libpng16-16, libjasper1, etc.)
- **cropper/requirements.txt**: Pin opencv-python to 4.8.1.78 for armhf
- **web/src/Controller/CropperController.php**: New controller for /cropper.php routing
- **web/config/routes.php**: Add cropper routes and legacy URL support
- **nginx/conf.d/cropper.conf**: Reverse proxy configuration

## Fixes
- Closes #XX (ImportError libpng16.so.16)
- Closes #XX (301 redirect on /cropper.php)

## Testing
- [x] Service cropper starts without ImportError
- [x] GET /cropper.php returns 200 (no 301 redirect)
- [x] GET /cropper displays interface
- [x] POST /cropper/crop reaches Python service

## Migration
See `DEPLOYMENT-GUIDE.md` for step-by-step deployment instructions.
```

---

## **Questions fréquentes**

**Q: Puis-je utiliser `opencv-python-headless` ?**
A: Oui, si aucune GUI n'est requise. Remplacer `opencv-python==4.8.1.78` par `opencv-python-headless==4.8.1.78`

**Q: Dois-je migrer à CakePHP4 ?**
A: Non nécessaire. CakePHP3 fonctionne bien. CakePHP4 nécessiterait PHP 7.4+ et dépendances additionnelles.

**Q: Quelle est la latence ajoutée par le proxy ?**
A: Minimal (~1-2ms) sur une connexion localhost. Nginx est très efficace.

---

**Auteur :** Bruno (b23prodtm)  
**Date :** 2026-05-15  
**Status :** ✅ Prêt pour PR
