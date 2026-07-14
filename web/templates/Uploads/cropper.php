<?php
$this->assign('title', 'Cropper');
?>

<?php $this->start('css'); ?>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.css">
<link rel="stylesheet" href="/assets/css/cropper.css">
<?php $this->end(); ?>

<div class="layout">
    <div class="header">
        <h1>Balena Photo Cropper</h1>
    </div>

    <div class="toolbar">
        <input type="file" id="fileInput" accept=".pdf,.tif,.tiff,.jpg,.jpeg">
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

<?php $this->start('script'); ?>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>
<script src="/assets/js/app.js"></script>
<?php $this->end(); ?>