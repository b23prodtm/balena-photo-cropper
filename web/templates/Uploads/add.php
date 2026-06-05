<?php
$this->assign('title', 'Nouvelle numérisation');
?>
<div class="container">
    <h1>Restaurer un scan</h1>
    <?= $this->Form->create(null, ['type' => 'file']) ?>
    <?= $this->Form->control('scan_file', ['type' => 'file', 'label' => 'Scan JPG/PDF', 'required' => true]) ?>
    <fieldset class="mt-3">
        <legend>Options de restauration</legend>
        <?= $this->Form->control('options.denoise', ['type' => 'checkbox', 'label' => 'Débruitage']) ?>
        <?= $this->Form->control('options.hdr', ['type' => 'checkbox', 'label' => 'Mode HDR (CLAHE)']) ?>
        <?= $this->Form->control('options.colorize', ['type' => 'checkbox', 'label' => 'Coloriser N&B (LUT 1Mo)']) ?>
        <?= $this->Form->control('options.ai_upscale', ['type' => 'checkbox', 'label' => 'Upscale IA x4 - lent ~3min/photo']) ?>
    </fieldset>
    <?= $this->Form->button(__('Lancer le traitement'), ['class' => 'btn btn-primary mt-3']) ?>
    <?= $this->Form->end() ?>
</div>