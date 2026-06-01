# Checklist & Commandes Git - Soumission PR

## **✅ Pre-PR Checklist**

### **1. Validation locale**
- [ ] Cloner le repo `balena-photo-cropper`
- [ ] Créer une branche feature : `git checkout -b fix/python-deps-cakephp-integration`
- [ ] Copier les fichiers modifiés dans le répertoire du projet
- [ ] Exécuter `docker-compose build` pour vérifier les builds
- [ ] Tester localement ou sur un appareil Balena test

### **2. Vérification des fichiers**
- [ ] `services/cropper/Dockerfile` → dépendances libpng16, libjasper, etc.
- [ ] `services/cropper/requirements.txt` → versions pinnées
- [ ] `services/web/src/Controller/CropperController.php` → nouveau fichier
- [ ] `services/web/config/routes.php` → routes cropper ajoutées
- [ ] `services/nginx/conf.d/cropper.conf` → nouvelle configuration

### **3. Tests fonctionnels**
- [ ] Service cropper démarre sans ImportError
- [ ] `curl http://localhost/cropper.php` → 200 OK (pas 301)
- [ ] `curl http://localhost/cropper` → affiche interface
- [ ] `curl -X POST http://localhost/cropper/crop` → atteint le service

### **4. Documentation**
- [ ] `PR-SUMMARY.md` → description détaillée des changements
- [ ] `DEPLOYMENT-GUIDE.md` → instructions d'implémentation
- [ ] Code commenté aux points critiques
- [ ] Commit messages clairs et descriptifs

---

## **📝 Commits recommandés**

### **Stratégie : 4 commits atomiques**

```bash
# 1. Fix dépendances cropper
git add services/cropper/Dockerfile services/cropper/requirements.txt
git commit -m "fix(cropper): add missing system dependencies for armhf OpenCV

- Add libpng16-16, libjasper1, libtiff5, libwebp6 to Dockerfile
- Pin opencv-python==4.8.1.78 for armhf wheels compatibility
- Fix: ImportError libpng16.so.16 on Raspberry Pi armhf
- Resolves: #XX

The ImportError was caused by missing system libraries that OpenCV
depends on when running on armhf architecture. Pre-compiled wheels
require these shared object files to be available at runtime."

# 2. Add CakePHP3 controller
git add services/web/src/Controller/CropperController.php
git commit -m "feat(web): add CakePHP3 CropperController for service routing

- New controller to proxy /cropper endpoints to Python service
- Support for GET /cropper (interface), POST /cropper/crop (API)
- Support for POST /cropper/upload (file upload)
- Proper error handling and HTTP status codes

This controller acts as a bridge between the CakePHP web frontend
and the Python cropper service, allowing the web interface to
communicate with the backend processing service."

# 3. Add routing configuration
git add services/web/config/routes.php
git commit -m "feat(web): add cropper routes and legacy URL support

- Add /cropper scope with index, crop, upload actions
- Add /cropper.php legacy URL rewrite
- Ensure backward compatibility with existing requests

Routes configuration enables the CakePHP router to direct requests
to the CropperController for processing."

# 4. Add Nginx reverse proxy configuration
git add services/nginx/conf.d/cropper.conf
git commit -m "feat(nginx): add reverse proxy configuration for cropper service

- Route /cropper/* to CakePHP3 web service
- Route /cropper/api/* to Python service (http://cropper:5000)
- Handle static assets caching
- Fix: 301 redirect issue on /cropper.php

Nginx now properly dispatches requests based on URL patterns,
eliminating the persistent 301 redirect issue."

# 5. Documentation (optional separate commit)
git add DEPLOYMENT-GUIDE.md PR-SUMMARY.md docker-compose.yml.example
git commit -m "docs: add deployment guide and configuration examples

- Add DEPLOYMENT-GUIDE.md with step-by-step instructions
- Add docker-compose.yml.example with full stack
- Add PR-SUMMARY.md with technical details
- Include troubleshooting section"
```

---

## **🚀 Étapes soumission PR**

### **1. Préparer la branche**

```bash
# Créer branche depuis main/master
git checkout main
git pull origin main
git checkout -b fix/python-deps-cakephp-integration

# Copier les fichiers depuis /mnt/user-data/outputs/
cp /mnt/user-data/outputs/cropper-Dockerfile.patch services/cropper/
cp /mnt/user-data/outputs/requirements.txt services/cropper/
cp /mnt/user-data/outputs/CropperController.php services/web/src/Controller/
# ... etc pour les autres fichiers

# Faire les commits (voir section 2 ci-dessus)
```

### **2. Vérifier avant le push**

```bash
# Lister les changements
git log --oneline -5
git status

# Vérifier que tous les fichiers sont stagés
git diff --name-only --cached
```

### **3. Push vers GitHub**

```bash
# Push la branche
git push origin fix/python-deps-cakephp-integration

# OU si vous utiliser un fork, pusher vers votre fork d'abord
git push origin fix/python-deps-cakephp-integration
```

### **4. Créer la PR sur GitHub**

**Titre PR :**
```
fix: resolve Python dependencies and add CakePHP3 integration
```

**Description PR (template):**

````markdown
## Description
Fix missing Python dependencies for cropper service on armhf (Raspberry Pi) and add CakePHP3 web interface integration to resolve routing issues.

## Problem
- Service cropper crashes with `ImportError: libpng16.so.16` on armhf
- Requests to `/cropper.php` return 301 redirect (routing not configured)
- No CakePHP3 component to handle web requests

## Solution
- Add system dependencies to Dockerfile (libpng16-16, libjasper1, etc.)
- Pin opencv-python to 4.8.1.78 (stable armhf wheels)
- Create CropperController.php for request routing
- Configure Nginx reverse proxy for proper URL dispatch

## Changes
- **cropper/Dockerfile**: Add system dependencies
- **cropper/requirements.txt**: Pin dependency versions
- **web/src/Controller/CropperController.php**: New controller
- **web/config/routes.php**: Add cropper routes
- **nginx/conf.d/cropper.conf**: Reverse proxy configuration

## Testing
- [x] Service cropper starts without ImportError
- [x] GET /cropper.php returns 200 (no redirect)
- [x] GET /cropper displays interface
- [x] POST /cropper/crop reaches service

## Related Issues
Closes #XX (ImportError on armhf)
Closes #XX (301 redirect on /cropper.php)

## Deployment Notes
See DEPLOYMENT-GUIDE.md for full implementation instructions.
````

### **5. Après ouverture de la PR**

```bash
# Attendre reviews
# Répondre aux commentaires
# Faire les changements demandés

# Si révisions demandées :
git checkout fix/python-deps-cakephp-integration
# ... faire changements ...
git add .
git commit -m "chore: address review feedback

- Change X per reviewer comment
- Fix Y for better compatibility"
git push origin fix/python-deps-cakephp-integration

# La PR se mettra à jour automatiquement
```

---

## **📋 Checklist avant merge**

Avant que la PR soit mergée :

- [ ] Au moins 1 approbation (review)
- [ ] Tous les commentaires adressés
- [ ] CI/tests passent (GitHub Actions si configuré)
- [ ] Pas de conflits merge
- [ ] Commits sont squashed si nécessaire
- [ ] Branch est up-to-date avec main

---

## **🔍 Vérification post-merge**

```bash
# Après merge, pull les changements
git checkout main
git pull origin main

# Vérifier que les commits sont bien présents
git log --oneline -10 | grep "cropper\|python\|CakePHP"

# Merger dans vos branches de développement
git checkout develop
git merge main
git push origin develop
```

---

## **⚠️ Troubleshooting Commits**

### **Si commits sont mal ordonnés**

```bash
# Rebase interactif (avant le push)
git rebase -i HEAD~4  # Réorder les 4 derniers commits
```

### **Si message de commit est mauvais**

```bash
# Amender le dernier commit
git commit --amend -m "nouveau message"

# Ou pour un commit précédent, rebase interactif
git rebase -i HEAD~2  # Puis "edit" le commit à modifier
```

### **Si oublié un fichier**

```bash
# Ajouter au dernier commit (avant push)
git add fichier-oublié.php
git commit --amend --no-edit
```

---

## **📞 Support & Questions**

Pour questions ou problèmes :
1. Commenter sur la PR GitHub
2. Ouvrir une discussion dans Issues
3. Contacter maintainer du projet

---

**Status PR :** 🟢 Prêt pour soumission  
**Date création :** 2026-05-15  
**Auteur :** Bruno (b23prodtm)
