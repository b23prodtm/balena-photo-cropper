<?php
$this->assign('title', 'Mes scans');
?>
<h1>Scans traités</h1>

<?php if (empty($files)): ?>
    <p>Aucun scan pour le moment.</p>
    <?= $this->Html->link('Uploader un scan', ['action' => 'add'], ['class' => 'button']) ?>
<?php else: ?>
    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem;">
        <?php foreach ($files as $file): ?>
            <div style="border: 1px solid #ddd; border-radius: 8px; padding: 1rem;">
                <img src="/uploads/<?= h($file) ?>" style="width: 100%; height: 150px; object-fit: cover; border-radius: 4px;">
                <p style="margin-top: 0.5rem; font-size: 0.9rem; word-break: break-all;"><?= h($file) ?></p>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>