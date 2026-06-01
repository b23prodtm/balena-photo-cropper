# 🚀 Instructions pour Soumettre la PR

## Méthode 1: Script Automatique (Recommandé - 2 minutes)

### Step 1: Télécharger le script
```bash
# Les fichiers sont dans /mnt/user-data/outputs/
cd /chemin/vers/balena-photo-cropper  # Votre répertoire du projet
```

### Step 2: Exécuter le script
```bash
bash /mnt/user-data/outputs/submit-pr.sh b23prodtm balena-photo-cropper
```

Le script va automatiquement:
- ✅ Créer la branche `fix/python-deps-cakephp-integration`
- ✅ Modifier les 5 fichiers nécessaires
- ✅ Créer 4 commits atomiques avec messages descriptifs
- ✅ Vous donner les instructions pour pusher

### Step 3: Pousser et créer la PR
```bash
# Le script vous dira ceci
git push origin fix/python-deps-cakephp-integration

# Puis aller sur GitHub et créer la PR avec la description fournie
```

---

## Méthode 2: Manuel (Détaillé - 10 minutes)

Si vous préférez faire manuellement, voici les étapes :

### Step 1: Créer et checkout la branche
```bash
cd /chemin/vers/balena-photo-cropper
git checkout -b fix/python-deps-cakephp-integration
```

### Step 2: Copier/modifier les fichiers

#### Fichier 1 : services/cropper/Dockerfile
```bash
# Copier le contenu de Dockerfile-cropper-OPTIMIZED.txt
cp /mnt/user-data/outputs/Dockerfile-cropper-OPTIMIZED.txt services/cropper/Dockerfile
```

#### Fichier 2 : services/cropper/requirements.txt
```bash
cp /mnt/user-data/outputs/requirements.txt services/cropper/requirements.txt
```

#### Fichier 3 : services/web/src/Controller/CropperController.php
```bash
mkdir -p services/web/src/Controller
cp /mnt/user-data/outputs/CropperController.php services/web/src/Controller/
```

#### Fichier 4 : services/web/config/routes.php
```bash
# Ajouter le contenu de routes-config.php AVANT la ligne Router::fallbacks
# Voir DEPLOYMENT-GUIDE.md pour détails
```

#### Fichier 5 : services/nginx/conf.d/cropper.conf
```bash
mkdir -p services/nginx/conf.d
cp /mnt/user-data/outputs/nginx-cropper.conf services/nginx/conf.d/
```

### Step 3: Créer les commits

```bash
# Commit 1
git add services/cropper/Dockerfile services/cropper/requirements.txt
git commit -m "fix(cropper): add missing system dependencies for armhf OpenCV

- Add libpng16-16, libjasper1, libtiff5, libwebp6 to Dockerfile
- Pin opencv-python==4.8.1.78 for armhf wheels compatibility
- Fix: ImportError libpng16.so.16 on Raspberry Pi armhf"

# Commit 2
git add services/web/src/Controller/CropperController.php
git commit -m "feat(web): add CakePHP3 CropperController for service routing

- New controller to proxy /cropper endpoints to Python service
- Support for GET /cropper (interface), POST /cropper/crop (API)
- Support for POST /cropper/upload (file upload)"

# Commit 3
git add services/web/config/routes.php
git commit -m "feat(web): add cropper routes and legacy URL support

- Add /cropper scope with index, crop, upload actions
- Add /cropper.php legacy URL rewrite
- Ensure backward compatibility"

# Commit 4
git add services/nginx/conf.d/cropper.conf
git commit -m "feat(nginx): add reverse proxy configuration for cropper service

- Route /cropper/* to CakePHP3 web service
- Route /cropper/api/* to Python service
- Fix: 301 redirect issue on /cropper.php"
```

### Step 4: Pousser
```bash
git push origin fix/python-deps-cakephp-integration
```

### Step 5: Créer la PR sur GitHub

1. Aller à https://github.com/b23prodtm/balena-photo-cropper
2. Cliquer sur "New Pull Request"
3. Sélectionner votre branche `fix/python-deps-cakephp-integration`
4. Utiliser cette description :

```markdown
## Description
Fix missing Python dependencies for cropper service on armhf (Raspberry Pi) and add CakePHP3 integration for web interface routing.

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
- [x] POST /cropper/crop reaches Python service

## Breaking Changes
None - fully backward compatible
```

---

## Vérification avant de pousser

```bash
# Vérifier les commits
git log --oneline -4

# Vérifier les fichiers modifiés
git status
git diff --stat

# Vérifier pas de conflits
git pull origin main --dry-run
```

---

## Après création de la PR

1. **Attendre les reviews**
2. **Répondre aux commentaires**
3. **Faire des changements si demandés**
   ```bash
   # Faire les changements
   git add .
   git commit -m "chore: address review feedback"
   git push origin fix/python-deps-cakephp-integration
   ```
4. **PR se met à jour automatiquement**

---

## En cas de problème

### "Merge conflict"
```bash
# Récupérer la version main
git fetch origin
git rebase origin/main
# Résoudre les conflits
git push origin fix/python-deps-cakephp-integration --force-with-lease
```

### "Permission denied"
```bash
# Vérifier que vous êtes connecté à GitHub
git config --list | grep github

# Ou utiliser SSH si HTTPS pose problème
git remote set-url origin git@github.com:b23prodtm/balena-photo-cropper.git
```

### "Branch is behind"
```bash
# Mettre à jour votre branche
git fetch origin
git rebase origin/main
git push origin fix/python-deps-cakephp-integration --force-with-lease
```

---

## Résumé

| Méthode | Temps | Complexité |
|---------|-------|-----------|
| **Script auto** | 2 min | Très simple |
| **Manuel** | 10 min | Moyen |

👉 **Recommandation:** Utiliser le script automatique !

```bash
bash /mnt/user-data/outputs/submit-pr.sh b23prodtm balena-photo-cropper
```

---

**Status :** 🟢 PR Prête à être soumise
