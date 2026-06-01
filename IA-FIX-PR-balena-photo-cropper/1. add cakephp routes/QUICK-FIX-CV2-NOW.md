# ⚡ QUICK FIX - ImportError cv2 libpng16 (Immédiat)

## 🚨 Problème actuel

```
<cropper> ImportError: libpng16.so.16: cannot open shared object file: No such file or directory
```

**Durée fix :** 5-10 minutes (rebuild Docker)

---

## 🔧 SOLUTION EN 3 ÉTAPES

### **Étape 1 : Modifier services/cropper/Dockerfile**

Remplacer la première partie par ceci (avant `pip install`) :

```dockerfile
FROM balena/rpi-python:3.11

# ← AJOUTER CES LIGNES (CRITICAL)
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
    libsm6 \
    libxrender1 \
    libxext6 \
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

---

### **Étape 2 : Mettre à jour services/cropper/requirements.txt**

Remplacer le contenu complet par :

```txt
opencv-python==4.8.1.78
numpy==1.24.3
Pillow>=9.5.0
requests>=2.28.0
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=20.1.0
```

**Clé :** Version 4.8.1.78 de opencv-python est compilée pour armhf

---

### **Étape 3 : Rebuild et redeploy**

```bash
# Depuis répertoire du projet
docker-compose build --no-cache cropper

# Redémarrer le service
docker-compose down cropper
docker-compose up -d cropper

# Vérifier les logs
docker logs cropper

# Vérifier pas d'ImportError
docker logs cropper | grep -i "import\|error" || echo "✅ OK"
```

---

## ✅ VALIDATION

Service doit démarrer sans erreur :

```bash
# Si OK
docker logs cropper | head -20
# → Ne doit PAS contenir "libpng16.so.16" ou "ImportError"

# Tester import cv2 directement
docker exec cropper python3 -c "import cv2; print('OpenCV:', cv2.__version__)"
# → Doit afficher version OpenCV (ex: OpenCV: 4.8.1)
```

---

## 📋 FICHIERS À MODIFIER

```
√ services/cropper/Dockerfile         ← Ajouter dépendances système
√ services/cropper/requirements.txt    ← Pinned versions
```

**C'est tout !** Les autres fichiers (CakePHP, Nginx) ne sont pas nécessaires pour fixer cv2.

---

## 🔍 SI ÇA NE MARCHE TOUJOURS PAS

### **Check 1 : Dockerfile a été modifié ?**

```bash
cat services/cropper/Dockerfile | head -20
# Doit contenir : libpng16-16, libjasper1, libtiff5, libwebp6
```

### **Check 2 : Build a utilisé le bon Dockerfile ?**

```bash
# Force rebuild complet
docker-compose build --no-cache --force-rm cropper
```

### **Check 3 : Vérifier les libs dans container**

```bash
docker run --rm balena/rpi-python:3.11 apt-get update && \
  apt-get install -y libpng16-16 && \
  python3 -m pip install opencv-python==4.8.1.78 && \
  python3 -c "import cv2; print('OK')"
```

---

## 📞 SUPPORT

Si toujours erreur après ces 3 étapes :

1. Vérifier le log complet : `docker logs cropper 2>&1 | head -50`
2. Checker Dockerfile syntaxe : `docker build -f services/cropper/Dockerfile .`
3. Vérifier base image disponible : `docker pull balena/rpi-python:3.11`

---

**Créé par :** Claude  
**Date :** 2026-05-15  
**Type :** Emergency Fix  
**Durée :** 5-10 min  
