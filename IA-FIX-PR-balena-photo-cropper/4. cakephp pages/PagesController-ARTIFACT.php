<?php
/**
 * CakePHP Pages Controller
 * Gère les pages statiques (HomePage avec README du projet)
 * 
 * Location: src/Controller/PagesController.php
 */

namespace App\Controller;

use Cake\Core\Configure;
use Cake\Http\Exception\ForbiddenException;
use Cake\Http\Exception\NotFoundException;
use Cake\View\Exception\MissingTemplateException;

/**
 * Static content controller
 *
 * This controller will render views from Template/Pages/
 *
 * @link https://book.cakephp.org/4/en/controllers/pages-controller.html
 */
class PagesController extends AppController
{
    /**
     * Displays a view
     *
     * @param string ...$path Path segments.
     * @return \Cake\Http\Response|null
     * @throws \Cake\Http\Exception\ForbiddenException When a directory traversal attempt.
     * @throws \Cake\Http\Exception\NotFoundException When the view file could not be found
     *   or MissingTemplateException in debug mode.
     */
    public function display(...$path)
    {
        if (!$path) {
            return $this->redirect('/');
        }

        if (in_array('..', $path, true) || in_array('.', $path, true)) {
            throw new ForbiddenException();
        }

        try {
            $this->set('page', $path[0]);
            return $this->render(implode('/', $path));
        } catch (MissingTemplateException $exception) {
            if (Configure::read('debug')) {
                throw $exception;
            }
            throw new NotFoundException();
        }
    }

    /**
     * HomePage action - Affiche le README du projet
     * Route: GET /
     * 
     * @return void
     */
    public function home()
    {
        $this->layout = 'default';
        
        // Lire le README du projet
        $readmePath = ROOT . DS . 'README.md';
        
        $readme = '';
        $projectInfo = [
            'name' => 'Photo Cropper',
            'description' => 'Image cropping service with CakePHP3 web interface',
            'version' => '1.0.0',
        ];
        
        if (file_exists($readmePath)) {
            $readme = file_get_contents($readmePath);
        } else {
            // README par défaut si fichier non trouvé
            $readme = $this->getDefaultReadme();
        }
        
        // Parser le markdown basiquement (pour affichage simple)
        $readmeHtml = $this->parseMarkdown($readme);
        
        $this->set(compact('readmeHtml', 'projectInfo'));
    }

    /**
     * Parse simple markdown to HTML
     * 
     * @param string $markdown Markdown content
     * @return string HTML content
     */
    private function parseMarkdown($markdown)
    {
        // Convertir les en-têtes
        $html = preg_replace('/^# (.+)$/m', '<h1>$1</h1>', $markdown);
        $html = preg_replace('/^## (.+)$/m', '<h2>$1</h2>', $html);
        $html = preg_replace('/^### (.+)$/m', '<h3>$1</h3>', $html);
        $html = preg_replace('/^#### (.+)$/m', '<h4>$1</h4>', $html);
        
        // Convertir les listes
        $html = preg_replace('/^- (.+)$/m', '<li>$1</li>', $html);
        $html = preg_replace('/(<li>.+<\/li>)/s', '<ul>$1</ul>', $html);
        
        // Convertir les blocs de code
        $html = preg_replace('/```(.+?)```/s', '<pre><code>$1</code></pre>', $html);
        
        // Convertir les liens
        $html = preg_replace('/\[(.+?)\]\((.+?)\)/', '<a href="$2">$1</a>', $html);
        
        // Convertir les paragraphes
        $lines = explode("\n", $html);
        $inCode = false;
        $inList = false;
        $result = [];
        
        foreach ($lines as $line) {
            $line = trim($line);
            
            if (empty($line)) {
                $result[] = '';
                continue;
            }
            
            if (strpos($line, '<pre><code>') !== false) {
                $inCode = true;
            }
            if (strpos($line, '</code></pre>') !== false) {
                $inCode = false;
            }
            
            if (strpos($line, '<ul>') !== false) {
                $inList = true;
            }
            if (strpos($line, '</ul>') !== false) {
                $inList = false;
            }
            
            if (!$inCode && !$inList && 
                !preg_match('/^<h[1-6]|^<p|^<ul|^<li|^<pre|^<code|^<a/', $line) &&
                !empty($line)) {
                $line = '<p>' . $line . '</p>';
            }
            
            $result[] = $line;
        }
        
        return implode("\n", $result);
    }

    /**
     * Retourne un README par défaut
     * 
     * @return string
     */
    private function getDefaultReadme()
    {
        return <<<'EOF'
# Photo Cropper - Image Cropping Service

## À propos

**Photo Cropper** est une application de **recadrage d'images** basée sur :
- **Frontend Web** : CakePHP 3 avec interface utilisateur
- **Backend** : Service Python avec OpenCV pour le traitement d'images
- **Infrastructure** : Docker Compose pour déploiement facile

## Caractéristiques

- ✅ Interface web conviviale pour recadrer les images
- ✅ Support de multiples formats (JPG, PNG, GIF, WebP)
- ✅ Traitement d'images haute performance avec OpenCV
- ✅ API REST pour intégration tierce
- ✅ Déploiement Docker Compose simple
- ✅ Raspberry Pi compatible

## Architecture

```
┌─────────────────────────────────────┐
│       Client (Navigateur)           │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   Nginx (Port 80)                   │
│   Reverse Proxy & Routeur           │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    ↓                     ↓
┌─────────────────┐   ┌──────────────────┐
│  CakePHP3       │   │  Python Service  │
│  Web Interface  │   │  (cv2/OpenCV)    │
│  (Port 9000)    │   │  (Port 5000)     │
└─────────────────┘   └──────────────────┘
```

## Services

### Web Service (PHP-FPM)
- **Framework** : CakePHP 3
- **Port** : 9000 (FPM interne)
- **Accessible via** : http://localhost/ ou http://localhost/cropper.php
- **Responsabilités** : Interface web, routage, authentification

### Cropper Service (Python)
- **Stack** : Flask + OpenCV
- **Port** : 5000
- **Endpoints** :
  - `GET /health` - Vérifier le statut du service
  - `POST /crop` - Recadrer une image
  - `POST /upload` - Uploader une image

### Nginx
- **Port** : 80
- **Responsabilités** : Reverse proxy, routage HTTP, static files

## Démarrage rapide

### Avec Docker Compose

```bash
# Cloner le projet
git clone https://github.com/b23prodtm/balena-photo-cropper.git
cd balena-photo-cropper

# Démarrer les services
docker-compose up -d

# Accéder à l'application
# Interface web : http://localhost
# API Cropper : http://localhost/cropper
```

## Stack technique

| Composant | Technologie | Version |
|-----------|-------------|---------|
| **Frontend** | CakePHP | 3.x |
| **Web Server** | Nginx | latest |
| **Backend** | Python | 3.11 |
| **Image Processing** | OpenCV | 4.8+ |
| **Infrastructure** | Docker | latest |
| **Orchestration** | Docker Compose | 3.8 |

## Routes disponibles

| Route | Méthode | Description |
|-------|---------|-------------|
| `/` | GET | Page d'accueil |
| `/cropper.php` | GET/POST | Interface recadrage (legacy) |
| `/cropper` | GET/POST | Interface recadrage |
| `/cropper/crop` | POST | Endpoint API recadrage |
| `/cropper/upload` | POST | Endpoint API upload |

---

**Status** : ✅ Production Ready
EOF;
    }
}
