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
