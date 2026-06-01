# 🐳 Guide Images Docker Officielles (pas Balena)

## Pourquoi utiliser Docker Officielles au lieu de Balena?

| Aspect | Docker Officielles | Balena |
|--------|-------------------|--------|
| **Maintenance** | ✅ Support officiel | ⚠️ Support communautaire |
| **Taille image** | ✅ Optimisée (slim) | ⚠️ Plus volumineux |
| **Compatibilité** | ✅ Universel (tout système) | ⚠️ Optimisé pour Raspberry Pi |
| **Sécurité** | ✅ Patchs rapides | ✅ Bons |
| **Multiarch** | ✅ Multi-architecture | ✅ Multi-architecture |
| **Comunauté** | ✅ Énorme (milliers) | ⚠️ Plus petite |

---

## 📦 Images Docker officielles utilisées

### Cropper Service (Python)
```dockerfile
FROM python:3.11-slim
```
- ✅ Image officielle Python Docker Hub
- ✅ Version slim (plus léger)
- ✅ Support de plusieurs architectures (arm32v7 pour Raspberry Pi)
- ✅ Librairie complète (apt-get, curl, etc.)

### Web Service (PHP)
```dockerfile
FROM php:7.4-fpm
```
- ✅ Image officielle PHP Docker Hub
- ✅ FPM version (pour Nginx)
- ✅ Extensions principales pré-compilées
- ✅ Multiarch support

### Nginx
```dockerfile
FROM nginx:latest
```
- ✅ Image officielle Nginx Docker Hub
- ✅ Configuration flexible
- ✅ Support multi-arch
- ✅ Mise à jour régulière

### Database & Cache
```dockerfile
mysql:5.7
redis:7-alpine
```
- ✅ Images officielles MySQL et Redis
- ✅ Versions stables
- ✅ Multiarch support

---

## 🚀 Comment utiliser?

### Option 1: Utiliser docker-compose-OFFICIAL.yml

```bash
# Copier le fichier
cp /mnt/user-data/outputs/docker-compose-OFFICIAL.yml docker-compose.yml

# Ou remplacer votre docker-compose.yml existant
# Et adapter les chemins d'accès

# Build et run
docker-compose build
docker-compose up -d
```

### Option 2: Utiliser les Dockerfiles individuels

```bash
# Cropper service
cp /mnt/user-data/outputs/Dockerfile-cropper-OFFICIAL.txt services/cropper/Dockerfile

# Web service
cp /mnt/user-data/outputs/Dockerfile-web-OFFICIAL.txt services/web/Dockerfile

# Nginx
cp /mnt/user-data/outputs/Dockerfile-nginx-OFFICIAL.txt services/nginx/Dockerfile

# Build
docker-compose build --no-cache
```

---

## 🔧 Modifications clés vs Balena

### Cropper (Python)

**Balena:**
```dockerfile
FROM balena/rpi-python:3.11
```

**Officiel:**
```dockerfile
FROM python:3.11-slim
```

**Avantages:**
- Support multi-architecture natif
- Pas de dépendance Balena
- Librairie standard Python complète

---

### Web (PHP)

**Balena (n'existait pas vraiment):**
```dockerfile
FROM balena/rpi-raspbian:bullseye
RUN apt-get install php-fpm
```

**Officiel:**
```dockerfile
FROM php:7.4-fpm
```

**Avantages:**
- PHP pré-compilé et optimisé
- FPM configuré correctement
- Extensions pré-compilées disponibles

---

### Nginx

**Balena:**
```dockerfile
FROM balena/rpi-nginx:latest
```

**Officiel:**
```dockerfile
FROM nginx:latest
```

**Avantages:**
- Nginx officiel maintenu par Docker
- Configuration standard
- Pas de customisation Balena inutile

---

## ✅ Compatibilité Raspberry Pi

### ⚠️ Important: Architecture ARM

Les images Python:3.11-slim et php:7.4-fpm **supportent plusieurs architectures** :

- ✅ `amd64` (x86-64)
- ✅ `arm32v7` (ARMv7 - Raspberry Pi 3/4/Zero2)
- ✅ `arm64v8` (ARMv8 - Pi 4B+ 64-bit)
- ✅ `arm32v6` (ARMv6 - Pi Zero/1)

Docker pull automatiquement la bonne image selon votre machine.

### ✅ Vérifier votre architecture

```bash
# Sur Raspberry Pi
uname -m
# arm32v7 ou armv7l = 32-bit
# aarch64 = 64-bit

# Avec Docker
docker version
```

---

## 🔨 Configuration Dockerfile-cropper-OFFICIAL.txt

### Points clés:

```dockerfile
FROM python:3.11-slim  # ← Image officielle, slim version

# Installer dépendances système (CRITICAL pour cv2)
RUN apt-get install -y \
    libpng16-16 \        # ← Pour OpenCV
    libjasper1 \
    libtiff5 \
    libwebp6 \
    ...

# Installer requirements Python
RUN pip install --no-cache-dir -r requirements.txt

# Santé check pour Docker
HEALTHCHECK --interval=30s ...
```

### Pas de Balena-isms:
- ❌ Pas de `RUN usermod ...` pour balena user
- ❌ Pas de mount points balena
- ❌ Pas de configuration Balena
- ✅ Pur Docker standard

---

## 📝 Fichiers à utiliser

| Fichier | Remplace | Raison |
|---------|----------|--------|
| `Dockerfile-cropper-OFFICIAL.txt` | `services/cropper/Dockerfile` | Python officiel |
| `Dockerfile-web-OFFICIAL.txt` | `services/web/Dockerfile` | PHP-FPM officiel |
| `Dockerfile-nginx-OFFICIAL.txt` | `services/nginx/Dockerfile` | Nginx officiel |
| `docker-compose-OFFICIAL.yml` | `docker-compose.yml` | Images officielles |

---

## 🐳 Build et Test

```bash
# Build les images
docker-compose -f docker-compose-OFFICIAL.yml build --no-cache

# Vérifier les images
docker images
# Vous devez voir:
# python:3.11-slim
# php:7.4-fpm
# nginx:latest
# mysql:5.7
# redis:7-alpine

# Démarrer les services
docker-compose -f docker-compose-OFFICIAL.yml up -d

# Vérifier les logs
docker-compose -f docker-compose-OFFICIAL.yml logs -f cropper

# Tester
curl http://localhost/cropper.php
```

---

## ⚠️ Différences comportement

### Utilisateur Docker

**Balena:**
- Utilisateur: `root` ou `balena`
- Dossiers: `/opt/balena`, etc.

**Officiel:**
- Utilisateur: `www-data` (PHP) ou `root` (services)
- Dossiers: `/app` (Python), `/var/www/html` (PHP), etc.

**Action:** Adapter les chemins d'accès dans docker-compose.yml

### Réseau

**Balena:**
- Réseau Balena propre

**Officiel:**
- Utilise Docker networks standard
- Meilleure intégration avec autres conteneurs

---

## 🔄 Migration depuis Balena

Si tu migres depuis Balena:

1. **Backup** ta configuration actuelle
2. **Copier** les Dockerfiles officiels
3. **Mettre à jour** docker-compose.yml
4. **Adapter** les chemins de volumes
5. **Rebuild** images
6. **Tester** services

```bash
# Exemple migration
git checkout -b fix/use-official-images
cp docker-compose-OFFICIAL.yml docker-compose.yml
cp Dockerfile-*-OFFICIAL.txt services/*/Dockerfile
docker-compose build --no-cache
docker-compose up -d
```

---

## ✅ Avantages finaux

✅ Pas de dépendance Balena  
✅ Utiliser images maintenues officiellement  
✅ Meilleure portabilité (pas juste Raspberry Pi)  
✅ Meilleur support communautaire  
✅ Compatible avec Docker Swarm, K8s, etc.  
✅ Plus facile à debugger  
✅ Tailles images plus petites (slim)  

---

## 📊 Comparaison taille images

```
balena/rpi-python:3.11 ............. ~850 MB
python:3.11-slim ................... ~120 MB  ← 7x plus petit!

balena/rpi-nginx:latest ............ ~150 MB
nginx:latest ....................... ~40 MB   ← 4x plus petit!

balena/rpi-raspbian:bullseye ....... ~200 MB
php:7.4-fpm ....................... ~120 MB  ← Plus optimisé!
```

---

**Status:** 🟢 Fichiers officiels prêts à utiliser  
**Compatibilité:** ✅ Raspberry Pi + Docker standard  
**Recommandation:** Utiliser les fichiers OFFICIAL  

