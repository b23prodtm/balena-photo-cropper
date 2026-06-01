# 🔧 Solution Complète - Erreur cv2 + Intégration CakePHP

## ❌ Problème 1 : ImportError cv2 (libpng16.so.16)

### Cause racine
L'erreur `ImportError: libpng16.so.16: cannot open shared object file` signifie que:
1. Les dépendances système ne sont pas installées **AVANT** `pip install opencv-python`
2. Le Dockerfile du service cropper n'installe pas les libs manquantes

### ✅ Solution - Dockerfile cropper CORRIGÉ

**Fichier: `services/cropper/Dockerfile`**

```dockerfile
# ⚠️ IMPORTANT: Commencer par image légère
FROM python:3.11-slim

# 🔴 ÉTAPE CRITIQUE: Installer dépendances système AVANT pip install
RUN apt-get update && apt-get install -y --no-install-recommends \
    # === Dépendances CRITIQUE pour OpenCV ===
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libwebpmux3 \
    \
    # === Headers de développement ===
    libpng-dev \
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    \
    # === Autres libs graphiques ===
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libharfbuzz0b \
    libfreetype6 \
    \
    # === Build tools ===
    build-essential \
    python3-pip \
    python3-dev \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# Copier requirements.txt
COPY requirements.txt .

# 🔴 ÉTAPE IMPORTANT: pip install APRÈS dépendances système
RUN pip install --no-cache-dir -r requirements.txt

# Copier l'application
COPY . /app

# Créer répertoires nécessaires
RUN mkdir -p /app/uploads /app/tmp && chmod +x /app/app.py

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Commande de démarrage
CMD ["python3", "-u", "app.py"]
```

### 📝 requirements.txt CORRIGÉ

**Fichier: `services/cropper/requirements.txt`**

```txt
# Versions stables pour armhf (Raspberry Pi)
opencv-python==4.8.1.78
numpy==1.24.3
Pillow>=9.5.0
requests>=2.28.0
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=20.1.0
```

### 🔍 Vérifier la correction

```bash
# 1. Rebuild SANS cache
docker-compose build --no-cache cropper

# 2. Démarrer le service
docker-compose up cropper

# 3. Vérifier les logs (doit PAS avoir ImportError)
docker logs photo-cropper-service | head -20

# 4. Test direct import
docker exec photo-cropper-service python3 -c "import cv2; print('✅ OpenCV OK:', cv2.__version__)"
```

**Expected output:**
```
✅ OpenCV OK: 4.8.1
```

---

## ❌ Problème 2 : Ajouter CakePHP modules au service web

### Structure existante vs. nouvelle

**Avant:**
```
services/web/
├── (fichiers PHP existants)
└── (pas de structure CakePHP complète)
```

**Après:**
```
services/web/
├── src/
│   └── Controller/
│       ├── PagesController.php  ← NOUVEAU
│       └── (autres controllers)
├── templates/
│   ├── Pages/
│   │   └── home.php            ← NOUVEAU
│   └── (autres templates)
├── config/
│   ├── routes.php              ← À MODIFIER
│   └── (autres configs)
├── (fichiers existants)
└── (structure CakePHP3)
```

### 📂 Étape 1: Créer les répertoires

```bash
# SSH dans le service web OU depuis ton système local
mkdir -p services/web/src/Controller
mkdir -p services/web/templates/Pages
```

### 📄 Étape 2: Ajouter PagesController.php

**Fichier: `services/web/src/Controller/PagesController.php`**

Copie le contenu de l'artifact **PagesController-ARTIFACT.php** que j'ai fourni plus haut.

```bash
# Depuis /mnt/user-data/outputs/:
cp PagesController-ARTIFACT.php services/web/src/Controller/PagesController.php
```

### 🎨 Étape 3: Ajouter home.php template

**Fichier: `services/web/templates/Pages/home.php`**

Copie le contenu de l'artifact **home-ARTIFACT.php** que j'ai fourni plus haut.

```bash
# Depuis /mnt/user-data/outputs/:
cp home-ARTIFACT.php services/web/templates/Pages/home.php
```

### 🛣️ Étape 4: Modifier config/routes.php

**Fichier: `services/web/config/routes.php`**

Ajouter **AVANT** la ligne `Router::fallbacks()` (ou équivalent):

```php
// ===== Pages statiques (HomePage) =====
$routes->connect('/', ['controller' => 'Pages', 'action' => 'home']);

// ===== Cropper routes =====
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
});

// Legacy support
$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
```

### 🔐 Étape 5: Vérifier permissions

```bash
# Vérifier les fichiers sont présents
ls -la services/web/src/Controller/PagesController.php
ls -la services/web/templates/Pages/home.php

# Vérifier routes.php est modifié
grep "Pages" services/web/config/routes.php
```

---

## 🚀 Déploiement Complet

### 1. Rebuild les services

```bash
# Rebuild TOUS les services avec les changements
docker-compose build --no-cache

# Ou juste ceux modifiés:
docker-compose build --no-cache cropper web nginx
```

### 2. Démarrer les services

```bash
# Arrêter les anciens containers
docker-compose down

# Démarrer les nouveaux
docker-compose up -d

# Vérifier les logs
docker-compose logs -f cropper
docker-compose logs -f web
docker-compose logs -f nginx
```

### 3. Tests

```bash
# Test 1: Erreur cv2 disparue?
docker logs photo-cropper-service | grep -i "importerror\|libpng" || echo "✅ Pas d'erreur cv2"

# Test 2: HomePage accessible?
curl http://localhost
# Doit retourner du HTML avec titre "Photo Cropper"

# Test 3: Interface Cropper accessible?
curl http://localhost/cropper.php
curl http://localhost/cropper
# Doit retourner du HTML (pas d'erreur 301)

# Test 4: API Cropper accessible?
curl http://localhost:5000/health
# Doit retourner 200 OK
```

---

## 📋 Checklist Complète

### Avant modification
- [ ] Backup docker-compose.yml
- [ ] Backup services/cropper/Dockerfile
- [ ] Backup services/web/config/routes.php

### Modification cv2
- [ ] Copier le Dockerfile cropper corrigé
- [ ] Copier requirements.txt
- [ ] docker-compose build --no-cache cropper
- [ ] Vérifier pas d'ImportError

### Modification CakePHP
- [ ] Créer services/web/src/Controller/
- [ ] Créer services/web/templates/Pages/
- [ ] Copier PagesController.php
- [ ] Copier home.php
- [ ] Modifier config/routes.php
- [ ] Vérifier permissions

### Test final
- [ ] docker-compose down
- [ ] docker-compose build --no-cache
- [ ] docker-compose up -d
- [ ] curl http://localhost → HomePage OK
- [ ] curl http://localhost/cropper → Cropper OK
- [ ] curl http://localhost:5000/health → API OK
- [ ] docker logs cropper → Pas d'erreur cv2

---

## 🐛 Troubleshooting

### Si cv2 error persiste

```bash
# Vérifier les libs sont installées
docker exec photo-cropper-service apt list --installed | grep libpng

# Vérifier Python peut les trouver
docker exec photo-cropper-service python3 -c "import ctypes; print(ctypes.CDLL('libpng16.so.16'))"

# Vérifier opencv-python version
docker exec photo-cropper-service pip show opencv-python
```

### Si HomePage ne s'affiche pas

```bash
# Vérifier le fichier existe
docker exec photo-cropper-web ls -la /var/www/html/src/Controller/PagesController.php

# Vérifier routes.php
docker exec photo-cropper-web grep "Pages" /var/www/html/config/routes.php

# Vérifier logs PHP
docker logs photo-cropper-web | tail -50
```

### Si /cropper.php retourne 301

```bash
# Vérifier nginx config
docker exec photo-cropper-nginx grep -A 5 "cropper" /etc/nginx/conf.d/*.conf

# Vérifier CropperController existe
docker exec photo-cropper-web ls -la /var/www/html/src/Controller/CropperController.php
```

---

## 📝 Résumé des actions

1. **Fixer cv2** → Modifier Dockerfile + requirements.txt + rebuild
2. **Ajouter CakePHP** → Créer répertoires + copier fichiers + modifier routes
3. **Redémarrer** → docker-compose down && up
4. **Tester** → curl http://localhost + vérifier logs

**Temps estimé:** 15-20 minutes

