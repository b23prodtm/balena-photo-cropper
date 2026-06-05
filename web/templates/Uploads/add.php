<?php
$this->assign('title', 'Nouvelle numérisation');
?>
<h1>Restaurer un scan</h1>
<?= $this->Form->create(null, ['type' => 'file']) ?>
<?= $this->Form->control('scan_file', ['type' => 'file', 'label' => 'Scan JPG/PDF', 'required' => true]) ?>
<fieldset style="margin-top: 1.5rem; padding: 1rem; border: 1px solid #ddd; border-radius: 8px;">
    <legend style="padding: 0 0.5rem; font-weight: 600;">Options de restauration</legend>
    <?= $this->Form->control('options.denoise', ['type' => 'checkbox', 'label' => ' Débruitage']) ?>
    <?= $this->Form->control('options.hdr', ['type' => 'checkbox', 'label' => ' Mode HDR (CLAHE)']) ?>
    <?= $this->Form->control('options.colorize', ['type' => 'checkbox', 'label' => ' Coloriser N&B (LUT 1Mo)']) ?>
    <?= $this->Form->control('options.ai_upscale', ['type' => 'checkbox', 'label' => ' Upscale IA x4 - lent ~3min/photo']) ?>
</fieldset>
<?= $this->Form->button(__('Lancer le traitement'), ['style' => 'margin-top: 1rem; padding: 0.75rem 1.5rem; background: #667eea; color: white; border: none; border-radius: 25px; cursor: pointer; font-weight: 600;']) ?>
<?= $this->Form->end() ?>