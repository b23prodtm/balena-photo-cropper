# Pull Request: Fix Python Dependencies + Add CakePHP3 Cropper Component

## **Résumé**

Cette PR corrige les dépendances manquantes pour le service **cropper** (Python/OpenCV sur armhf) et ajoute un composant **CakePHP 3** pour router les requêtes HTTP vers `/cropper.php` vers le service Python.

## **Problèmes résolus**

### **1. ImportError cv2 sur armhf** 
**Erreur :**
```
ImportError: libpng16.so.16: cannot open shared object file: No such file or directory
```

**Cause :** Dépendances système manquantes pour opencv-python compilé natif sur Raspberry Pi (armhf).

**Solution :** 
- Ajouter `libpng16-16`, `libjasper1`, `libtiff5`, `libwebp6` au Dockerfile cropper
- Pinning `opencv-python==4.8.1.78` avec wheels armhf pré-compilées
- Installation via `pip3` après dépendances système

---

### **2. Redirection 301 persistante vers /cropper.php**
**Symptôme :**
```
GET /cropper.php HTTP/1.1" 301 169
```

**Cause :** 
- Route nginx manquante pour `/cropper.php`
- Service web CakePHP3 non configuré pour recevoir les requêtes
- Aucune page d'accueil pointant vers `/cropper`

**Solution :**
- Créer **CropperController.php** (CakePHP3) qui route les requêtes vers le service Python
- Configurer nginx pour dispatcher :
  - `/cropper` → CakePHP3 (interface web)
  - `/cropper/api/*` → Service Python (endpoint API)
  - `/cropper.php` → Réécriture vers `/cropper`

---

## **Fichiers modifiés/ajoutés**

### **A. `Dockerfile` (service cropper)**

```dockerfile
# Additions critiques :
RUN apt-get update && apt-get install -y \
    libpng16-16 \              # ← Fix ImportError
    libjasper1 \               # ← JPEG support
    libtiff5 \                 # ← TIFF support  
    libwebp6 \                 # ← WebP support
    python3-dev \              # ← Build tools
    build-essential \
    ...
```

**Impact :** Cropper service démarre sans erreurs ImportError

---

### **B. `requirements.txt`**

```txt
opencv-python==4.8.1.78      # Pinned pour armhf wheels
numpy>=1.21.0,<1.26.0        # Stable sur ARM
Pillow>=9.0.0
```

**Impact :** Installation fiable sur Raspberry Pi armhf

---

### **C. `src/Controller/CropperController.php` (CakePHP3)**

Nouveau contrôleur qui :
- `GET /cropper` → Affiche interface cropper (proxy du service Python)
- `POST /cropper/crop` → Opération de crop (API)
- `POST /cropper/upload` → Upload d'image

**Code clé :**
```php
public function index()
{
    $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
    $client = new \Cake\Http\Client();
    
    // Forward request to Python service
    $response = $client->get($cropperServiceUrl);
    return $this->response->withStringBody($response->getStringBody());
}
```

---

### **D. `config/routes.php`**

Nouvelles routes :
```php
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    $routes->connect('/', ['action' => 'index']);        // /cropper
    $routes->connect('/crop', ['action' => 'crop']);     // /cropper/crop
    $routes->connect('/upload', ['action' => 'upload']); // /cropper/upload
});

// Legacy support
$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);
```

---

### **E. Nginx configuration (`/etc/nginx/conf.d/cropper.conf`)**

Upstream blocks :
```nginx
upstream cropper_service {
    server cropper:5000;
}

location ~ ^/cropper/(api|crop|upload)/ {
    proxy_pass http://cropper_service;        # → Service Python
    proxy_set_header X-Real-IP $remote_addr;
    ...
}

location /cropper {
    try_files $uri @cropper_cake;             # → Fallback CakePHP
}

location @cropper_cake {
    rewrite ^ /index.php?$request_uri break;
    fastcgi_pass web_service;                 # → Web service (PHP-FPM)
}
```

---

## **Flux de requête après correction**

```
Client HTTP Request
        ↓
   ┌─────────────────────┐
   │  Nginx (reverse     │
   │  proxy)             │
   └──────────┬──────────┘
              │
    ┌─────────┼─────────┐
    ↓         ↓         ↓
GET /     GET /cropper  POST /cropper/crop
    │         │           │
    ↓         ↓           ↓
[Pages]  [CakePHP3] → [Python Service]
         CropperCtl      (cv2 cropping)
         (forwards)
```

---

## **Tests & Validation**

### **1. Service Cropper (Python)**
```bash
# Vérifier l'import cv2
docker exec cropper python3 -c "import cv2; print(cv2.__version__)"
# Expected: 4.8.1 (sans ImportError)

# Vérifier API
curl http://localhost:5000/health
# Expected: 200 OK
```

### **2. Interface Web (CakePHP3)**
```bash
# Requête interface
curl http://localhost/cropper.php
curl http://localhost/cropper
# Expected: 200 OK (HTML page cropper)

# Redirection legacy
curl -L http://localhost/cropper.php | head -c 100
# Expected: Contenu interface cropper (pas 301)
```

### **3. API Cropper**
```bash
# POST crop operation
curl -X POST http://localhost/cropper/crop \
  -H "Content-Type: application/json" \
  -d '{"image":"...", "box":[0,0,100,100]}'
# Expected: 200 OK + JSON response
```

---

## **Notes d'implémentation**

### **Pour armhf (Raspberry Pi)**
- `opencv-python-headless` peut être utilisé à la place si aucune GUI n'est requise
- **Alternatively :** `FROM balena/raspberry-pi-python:3.11`

### **Variables d'environnement**
Ajouter à `docker-compose.yml` ou balena.yml :
```yaml
services:
  web:
    environment:
      CROPPER_SERVICE_URL: "http://cropper:5000"
```

### **Problèmes connus/futurs**
- [ ] Timeout possible (30s) sur crops volumineux → augmenter si nécessaire
- [ ] Cache HTTP pour assets statiques → implémenter Cache-Control header
- [ ] Authentification API → ajouter si sensible

---

## **Backward Compatibility**
✅ **Complète** - Les anciennes requêtes `/cropper.php` sont reroutes vers la nouvelle interface

---

## **Checklist PR**
- [x] Dockerfile cropper corrigé (dépendances libpng, etc.)
- [x] requirements.txt pinné pour armhf
- [x] CakePHP3 CropperController ajouté
- [x] Routes configurées
- [x] Nginx config fournies (exemple)
- [x] Documentation flux requête
- [x] Tests manuels validés

---

**Type :** Bug fix + Feature (CakePHP integration)  
**Breaking Changes :** Non  
**Migration Guide :** Voir instructions déploiement ci-dessus
