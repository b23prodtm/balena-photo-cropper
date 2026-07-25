let cropper = null;

const fileInput = document.getElementById('fileInput');
const image = document.getElementById('cropImage');
const pagesContainer = document.getElementById('pages');
const resetBtn = document.getElementById('resetBtn');
const rotateBtn = document.getElementById('rotateBtn');
const exportBtn = document.getElementById('exportBtn');

// Zone de drop = tout le workspace
const dropZone = document.querySelector('.canvas-panel') || document.body;

fileInput.addEventListener('change', async (event) => {
    const file = event.target.files[0];
    if (file) await handleFileUpload(file);
});

// Drag & Drop
['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, preventDefaults, false);
});

['dragenter', 'dragover'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => dropZone.classList.add('drag-over'), false);
});

['dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => dropZone.classList.remove('drag-over'), false);
});

dropZone.addEventListener('drop', async (e) => {
    const file = e.dataTransfer.files[0];
    if (file) await handleFileUpload(file);
});

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

async function handleFileUpload(file) {
    const formData = new FormData();
    formData.append('file', file);

    try {
        const response = await fetch('/uploads/upload', {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (!data.success) {
            alert('Upload failed: ' + (data.error || 'unknown'));
            return;
        }

        renderPages(data.pages);

        if (data.pages.length > 0) {
            loadPage(data.pages[0]);
        }
    } catch (err) {
        console.error('Upload error:', err);
        alert('Erreur réseau');
    }
}

function renderPages(pages) {
    pagesContainer.innerHTML = '';

    pages.forEach((page) => {
        const img = document.createElement('img');

        img.src = page;
        img.style.width = '100%';
        img.style.cursor = 'pointer';
        img.style.border = '2px solid transparent';
        img.style.marginBottom = '0.5rem';

        img.addEventListener('click', () => {
            pagesContainer.querySelectorAll('img').forEach(i => i.style.borderColor = 'transparent');
            img.style.borderColor = '#667eea';
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
    if (cropper) cropper.reset();
});

rotateBtn.addEventListener('click', () => {
    if (cropper) cropper.rotate(90);
});

exportBtn.addEventListener('click', async () => {
    if (!cropper) return;

    const canvas = cropper.getCroppedCanvas({
        maxWidth: 4096,
        maxHeight: 4096,
        imageSmoothingEnabled: true,
        imageSmoothingQuality: 'high'
    });

    canvas.toBlob(async (blob) => {
        const formData = new FormData();
        formData.append('crop', blob, 'crop.jpg');

        try {
            const response = await fetch('/uploads/save-crop', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();

            if (result.success) {
                window.open(result.file, '_blank');
            } else {
                alert('Erreur sauvegarde crop');
            }
        } catch (err) {
            console.error('Export error:', err);
            alert('Erreur réseau lors de l\'export');
        }
    }, 'image/jpeg', 0.95);
});