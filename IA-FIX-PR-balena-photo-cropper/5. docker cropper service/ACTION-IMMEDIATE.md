# ⚡ ACTION IMMÉDIATE - 15 minutes max

## 🔴 Problème 1: Fixer cv2 ImportError (5 min)

### Commande UNIQUE (copie-colle):

```bash
# 1. Remplacer le Dockerfile cropper
cp /mnt/user-data/outputs/Dockerfile-cropper-FINAL-FIX.txt services/cropper/Dockerfile

# 2. Copier requirements.txt corrigé
cp /mnt/user-data/outputs/requirements.txt services/cropper/requirements.txt

# 3. Rebuild SANS cache
docker-compose build --no-cache cropper

# 4. Redémarrer
docker-compose down cropper
docker-compose up -d cropper

# 5. Vérifier (doit PAS avoir d'erreur)
docker logs photo-cropper-service | head -30
```

**Expected result:** ✅ Service démarre sans ImportError libpng16

---

## 🟡 Problème 2: Ajouter CakePHP (10 min)

### Étape 1: Créer répertoires

```bash
mkdir -p services/web/src/Controller
mkdir -p services/web/templates/Pages
```

### Étape 2: Copier les fichiers

```bash
# PagesController
cp /mnt/user-data/outputs/PagesController-ARTIFACT.php \
   services/web/src/Controller/PagesController.php

# HomePage template
cp /mnt/user-data/outputs/home-ARTIFACT.php \
   services/web/templates/Pages/home.php
```

### Étape 3: Modifier routes.php

Ouvrir `services/web/config/routes.php` et ajouter AVANT `Router::fallbacks()`:

```php
// Pages
$routes->connect('/', ['controller' => 'Pages', 'action' => 'home']);

// Cropper routes
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
});

$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
```

### Étape 4: Redémarrer

```bash
docker-compose build --no-cache web
docker-compose down
docker-compose up -d
```

---

## ✅ Vérification (2 min)

```bash
# Test 1: cv2 OK?
docker logs photo-cropper-service | grep -i "importerror" || echo "✅ cv2 OK"

# Test 2: HomePage?
curl http://localhost | grep -q "Photo Cropper" && echo "✅ HomePage OK"

# Test 3: Cropper?
curl http://localhost/cropper | head -c 100 && echo "✅ Cropper OK"

# Test 4: API?
curl http://localhost:5000/health && echo "✅ API OK"
```

---

## 📝 Fichiers utilisés

| Fichier | Copie depuis | Copie vers |
|---------|--------------|-----------|
| Dockerfile-cropper-FINAL-FIX.txt | /mnt/user-data/outputs/ | services/cropper/Dockerfile |
| requirements.txt | /mnt/user-data/outputs/ | services/cropper/requirements.txt |
| PagesController-ARTIFACT.php | /mnt/user-data/outputs/ | services/web/src/Controller/PagesController.php |
| home-ARTIFACT.php | /mnt/user-data/outputs/ | services/web/templates/Pages/home.php |
| routes.php | Modifier | services/web/config/routes.php |

---

## 🐛 Si encore ImportError cv2

```bash
# Vérifier les libs système existent
docker exec photo-cropper-service apt list --installed | grep libpng

# Vérifier opencv installé
docker exec photo-cropper-service pip list | grep opencv

# Test import direct
docker exec photo-cropper-service python3 << 'PYEOF'
try:
    import cv2
    print("✅ cv2 OK:", cv2.__version__)
except ImportError as e:
    print("❌ Erreur:", e)
PYEOF
```

---

## ⏱️ Timeline

```
Fixer cv2 ............. 5 min
Ajouter CakePHP ....... 10 min
Tester ............... 2 min
───────────────────────────
TOTAL ................ 17 min ✅
```

---

**Status:** 🟢 Prêt à exécuter NOW  
**Difficulty:** ⭐ Très simple (copie-colle + une modification)  

