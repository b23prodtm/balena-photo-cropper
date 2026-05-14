#!/usr/bin/env bash

set -e

BRANCH_NAME="feature/web-ui-cropper"
BASE_BRANCH="balena-deploy"

echo "========================================="
echo " Balena Photo Cropper Web UI Installer "
echo "========================================="

echo ""
echo "[1/10] Vérification du dépôt git..."

if [ ! -d ".git" ]; then
    echo "Erreur: ce dossier n'est pas un dépôt git."
    exit 1
fi

echo ""
echo "[2/10] Changement de branche..."

git checkout ${BASE_BRANCH}
git pull origin ${BASE_BRANCH}

echo ""
echo "[3/10] Création branche ${BRANCH_NAME}..."

git checkout -b ${BRANCH_NAME} || git checkout ${BRANCH_NAME}

echo ""
echo "[4/10] Création arborescence..."

mkdir -p web/assets/css
mkdir -p web/assets/js
mkdir -p web/assets/uploads
mkdir -p web/templates
mkdir -p src/Controller

echo ""
echo "[5/10] Création CSS..."

cat > web/assets/css/cropper.css <<'EOF'
html,
body {
    margin: 0;
    padding: 0;
    font-family: Arial, sans-serif;
    background: #1e1e1e;
    color: white;
    height: 100%;
}

.layout {
    display: flex;
    flex-direction: column;
    height: 100vh;
}

.header {
    padding: 10px;
    background: #2b2b2b;
    border-bottom: 1px solid #444;
}

.toolbar {
    display: flex;
    gap: 10px;
    padding: 10px;
    background: #252525;
}

.workspace {
    display: flex;
    flex: 1;
    overflow: hidden;
}

.sidebar {
    width: 220px;
    overflow-y: auto;
    background: #111;
    border-right: 1px solid #333;
    padding: 10px;
}

.sidebar img {
    width: 100%;
    margin-bottom: 10px;
    cursor: pointer;
    border: 2px solid transparent;
}

.sidebar img:hover {
    border-color: #4ea1ff;
}

.canvas-panel {
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    overflow: hidden;
}

.canvas-panel img {
    max-width: 100%;
    max-height: 100%;
}

button {
    background: #4ea1ff;
    border: none;
    color: white;
    padding: 10px 14px;
    cursor: pointer;
}
EOF

echo ""
echo "[6/10] Création frontend JS..."

cat > web/assets/js/app.js <<'EOF'
let cropper = null;

const fileInput = document.getElementById('fileInput');
const image = document.getElementById('cropImage');
const pagesContainer = document.getElementById('pages');

const resetBtn = document.getElementById('resetBtn');
const rotateBtn = document.getElementById('rotateBtn');
const exportBtn = document.getElementById('exportBtn');

fileInput.addEventListener('change', async (event) => {
    const file = event.target.files[0];

    if (!file) {
        return;
    }

    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData
    });

    const data = await response.json();

    if (!data.success) {
        alert('Upload failed');
        return;
    }

    renderPages(data.pages);

    if (data.pages.length > 0) {
        loadPage(data.pages[0]);
    }
});

function renderPages(pages) {
    pagesContainer.innerHTML = '';

    pages.forEach((page) => {
        const img = document.createElement('img');

        img.src = page;

        img.addEventListener('click', () => {
            loadPage(page);
        });

        pagesContainer.appendChild(img);
    });
}

function loadPage(page) {
    image.src = page;

    image.onload = () => {
        if (cropper) {
            cropper.destroy();
        }

        cropper = new Cropper(image, {
            viewMode: 1,
            autoCropArea: 1,
            movable: true,
            zoomable: true,
            scalable: true,
            rotatable: true,
            responsive: true,
            background: false,
            wheelZoomRatio: 0.1
        });
    };
}

resetBtn.addEventListener('click', () => {
    if (cropper) {
        cropper.reset();
    }
});

rotateBtn.addEventListener('click', () => {
    if (cropper) {
        cropper.rotate(90);
    }
});

exportBtn.addEventListener('click', async () => {
    if (!cropper) {
        return;
    }

    const canvas = cropper.getCroppedCanvas();

    canvas.toBlob(async (blob) => {
        const formData = new FormData();
        formData.append('crop', blob, 'crop.jpg');

        const response = await fetch('/api/save-crop', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();

        if (result.success) {
            window.open(result.file, '_blank');
        }
    }, 'image/jpeg');
});
EOF

echo ""
echo "[7/10] Création template PHP..."

cat > web/templates/cropper.php <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Balena Photo Cropper</title>

    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.css">

    <link rel="stylesheet" href="/assets/css/cropper.css">
</head>
<body>

<div class="layout">

    <div class="header">
        <h1>Balena Photo Cropper</h1>
    </div>

    <div class="toolbar">
        <input
            type="file"
            id="fileInput"
            accept=".pdf,.tif,.tiff,.jpg,.jpeg"
        >

        <button id="resetBtn">Reset</button>
        <button id="rotateBtn">Rotate</button>
        <button id="exportBtn">Export</button>
    </div>

    <div class="workspace">

        <div class="sidebar" id="pages"></div>

        <div class="canvas-panel">
            <img id="cropImage">
        </div>

    </div>

</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>
<script src="/assets/js/app.js"></script>

</body>
</html>
EOF

echo ""
echo "[8/10] Création ApiController.php..."

cat > src/Controller/ApiController.php <<'EOF'
<?php
namespace App\Controller;

use Cake\Controller\Controller;

class ApiController extends Controller
{
    public function cropper()
    {
    }

    public function upload()
    {
        $this->request->allowMethod(['post']);

        $file = $this->request->getData('file');

        if (!$file) {
            return $this->response
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'success' => false
                ]));
        }

        $filename = uniqid() . '_' . $file->getClientFilename();

        $target = WWW_ROOT . 'uploads/' . $filename;

        $file->moveTo($target);

        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'pages' => [
                    '/uploads/' . $filename
                ]
            ]));
    }

    public function saveCrop()
    {
        $this->request->allowMethod(['post']);

        $file = $this->request->getData('crop');

        $filename = 'crop_' . uniqid() . '.jpg';

        $target = WWW_ROOT . 'uploads/' . $filename;

        $file->moveTo($target);

        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'file' => '/uploads/' . $filename
            ]));
    }
}
EOF

echo ""
echo "[9/10] Commit git..."

git add .

git commit -m "feat(web-ui): add browser cropper interface" || true

echo ""
echo "[10/10] Terminé"

echo ""
echo "========================================="
echo " Branche créée : ${BRANCH_NAME}"
echo "========================================="

echo ""
echo "Push:"
echo ""
echo "git push origin ${BRANCH_NAME}"
echo ""
echo "URL finale:"
echo ""
echo "http://<balena-device-ip>/cropper"
