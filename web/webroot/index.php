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
