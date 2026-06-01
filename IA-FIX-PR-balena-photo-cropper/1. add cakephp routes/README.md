# PR: Python Dependencies Fix + CakePHP3 Integration

## 📦 Contenu du package PR

Ce package contient tous les fichiers et documentation nécessaires pour soumettre une PR au repo `balena-photo-cropper` qui :

1. **Corrige l'erreur `ImportError: libpng16.so.16`** sur armhf (Raspberry Pi)
2. **Ajoute l'intégration CakePHP3** pour router `/cropper.php`
3. **Configure Nginx** pour dispatcher les requêtes HTTP

---

## 📂 Fichiers inclus

### **Fichiers de code (à intégrer dans le repo)**

| Fichier | Destination | Description |
|---------|-------------|-------------|
| `cropper-Dockerfile.patch` | `services/cropper/Dockerfile` | Fixes dépendances système OpenCV |
| `requirements.txt` | `services/cropper/requirements.txt` | Versions Python pinnées pour armhf |
| `CropperController.php` | `services/web/src/Controller/CropperController.php` | Nouveau contrôleur CakePHP3 |
| `routes-config.php` | `services/web/config/routes.php` | Ajouter ces routes au fichier existant |
| `nginx-cropper.conf` | `services/nginx/conf.d/cropper.conf` | Configuration Nginx reverse proxy |

### **Documentation**

| Fichier | Contenu |
|---------|---------|
| **PR-SUMMARY.md** | Description technique complète de la PR |
| **DEPLOYMENT-GUIDE.md** | Instructions étape-par-étape pour implémenter |
| **GIT-WORKFLOW.md** | Commandes Git et checklist pour soumettre |
| **docker-compose.yml.example** | Configuration Docker complète (référence) |
| **balena.yml.example** | Configuration Balena Cloud (référence) |

---

## 🚀 Quick Start

### **1. Préparer votre environnement local**

```bash
# Clone le repo
git clone https://github.com/votre-username/balena-photo-cropper.git
cd balena-photo-cropper

# Créer une branche feature
git checkout -b fix/python-deps-cakephp-integration
```

### **2. Appliquer les changements**

**Option A : Copie manuelle**
```bash
# Cropper service
cp <chemin>/cropper-Dockerfile.patch services/cropper/Dockerfile
cp <chemin>/requirements.txt services/cropper/

# Web service
mkdir -p services/web/src/Controller
cp <chemin>/CropperController.php services/web/src/Controller/

# Routes (ajouter le contenu à routes.php existant)
# Nginx (nouveau fichier ou intégrer à conf existante)
mkdir -p services/nginx/conf.d
cp <chemin>/nginx-cropper.conf services/nginx/conf.d/
```

**Option B : Patch (si patch standard)**
```bash
cd services/cropper
patch < Dockerfile.patch
```

### **3. Tester localement**

```bash
# Build les images
docker-compose build

# Démarrer les services
docker-compose up -d

# Vérifier pas d'ImportError
docker logs <cropper-container>

# Tester l'interface
curl http://localhost/cropper.php
curl http://localhost/cropper
```

### **4. Commit et push**

```bash
# Voir GIT-WORKFLOW.md pour commandes détaillées
git add services/cropper/
git commit -m "fix(cropper): add missing system dependencies for armhf OpenCV"

# Push vers GitHub
git push origin fix/python-deps-cakephp-integration
```

### **5. Créer la PR**

- Aller sur GitHub
- Créer une nouvelle PR depuis votre branche
- Utiliser le template dans `GIT-WORKFLOW.md`
- Décrire les changements et fixes

---

## 🔍 Vérification rapide

### **Service cropper - ImportError fix**

```bash
# Test 1: CV2 import works
docker exec cropper python3 -c "import cv2; print('OK')"
# Expected: OK (sans ImportError)

# Test 2: Service accessible
curl http://localhost:5000/health
# Expected: 200 OK
```

### **Interface web - Routing fix**

```bash
# Test 3: /cropper.php accessible
curl -i http://localhost/cropper.php
# Expected: 200 OK (pas 301 redirect)

# Test 4: /cropper interface
curl http://localhost/cropper | head -c 100
# Expected: Contenu HTML page cropper
```

### **API - Proxy fonctionne**

```bash
# Test 5: API endpoint
curl -X POST http://localhost/cropper/crop \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}'
# Expected: Réponse du service Python (pas erreur proxy)
```

---

## 📝 Fichiers clés à comprendre

### **1. cropper-Dockerfile.patch**
- **Problème :** `libpng16.so.16` manquante
- **Solution :** Ajouter dépendances système avant `pip install`
- **Impact :** Service cropper démarre sans ImportError

### **2. requirements.txt**
- **Problème :** Versions numpy/opencv incompatibles avec armhf
- **Solution :** Pinning versions stables
- **Impact :** Installation fiable sur Raspberry Pi

### **3. CropperController.php**
- **Problème :** Pas de route CakePHP3 pour `/cropper.php`
- **Solution :** Nouveau contrôleur qui proxy vers service Python
- **Impact :** Requêtes HTTP arrivent au bon service

### **4. nginx-cropper.conf**
- **Problème :** Nginx ne sait pas dispatcher `/cropper.php`
- **Solution :** Location blocks pour router par pattern URL
- **Impact :** Plus de 301 redirect, requêtes arrivent au service

---

## ⚠️ Points importants

### **Compatibilité**
- ✅ Compatible Raspberry Pi armhf
- ✅ Compatible CakePHP 3.x
- ✅ Compatible Nginx 1.15+
- ✅ Pas de breaking changes

### **Architecture finale**
```
Client
  ↓
Nginx (reverse proxy)
  ├→ /cropper.php → CakePHP3 (port 9000)
  ├→ /cropper → CakePHP3 (port 9000)
  └→ /cropper/crop → Python service (port 5000)
```

### **Dépendances ajoutées**
- Système : libpng16-16, libjasper1, libtiff5, libwebp6
- Python : aucune nouvelle (versions pinnées seulement)
- PHP : aucune nouvelle (Cake\Http\Client built-in)

---

## 🔧 Dépannage

### **ImportError toujours présent après build**
```bash
# Vérifier que Dockerfile inclut les dépendances
docker logs cropper | grep -i "libpng\|import"

# Rebuild sans cache
docker-compose build --no-cache cropper
docker-compose up cropper
```

### **301 redirect sur /cropper.php**
```bash
# Vérifier routes.php
grep -n "cropper.php" services/web/config/routes.php

# Vérifier nginx config
grep -A 5 "cropper.php" services/nginx/conf.d/cropper.conf
```

### **Service inaccessible**
```bash
# Vérifier networks
docker network ls | grep photo

# Vérifier services running
docker ps | grep cropper | grep -v nginx
```

---

## 📚 Documentation supplémentaire

**Consulter ces fichiers pour plus de détails :**

1. **PR-SUMMARY.md** → Description technique complète
2. **DEPLOYMENT-GUIDE.md** → Instructions d'implémentation détaillées
3. **GIT-WORKFLOW.md** → Commandes Git et checklist
4. **docker-compose.yml.example** → Stack complète de référence

---

## ✅ Checklist avant submission

- [ ] Tous les fichiers de code copiés aux bons emplacements
- [ ] `docker-compose build` passe sans erreur
- [ ] Services démarrent : `docker-compose up -d`
- [ ] `curl localhost/cropper.php` → 200 OK (pas 301)
- [ ] `docker logs cropper` → pas d'ImportError
- [ ] Commits sont clairs et descriptifs
- [ ] PR description utilise le template
- [ ] Branch est à jour avec main

---

## 📞 Questions ?

Voir **GIT-WORKFLOW.md** pour support et contact maintainer.

---

**Status :** ✅ Prêt pour soumission PR  
**Date :** 2026-05-15  
**Créé par :** Bruno (b23prodtm)
