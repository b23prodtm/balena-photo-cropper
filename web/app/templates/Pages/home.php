<?php
/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link      https://cakephp.org CakePHP(tm) Project
 * @since     0.10.0
 * @license   https://opensource.org/licenses/mit-license.php MIT License
 * @var \App\View\AppView $this
 */
use Cake\Cache\Cache;
use Cake\Core\Configure;
use Cake\Core\Plugin;
use Cake\Datasource\ConnectionManager;
use Cake\Error\Debugger;
use Cake\Http\Exception\NotFoundException;

$this->disableAutoLayout();

$checkConnection = function (string $name) {
    $error = null;
    $connected = false;
    try {
        ConnectionManager::get($name)->getDriver()->connect();
        // No exception means success
        $connected = true;
    } catch (Exception $connectionError) {
        $error = $connectionError->getMessage();
        if (method_exists($connectionError, 'getAttributes')) {
            $attributes = $connectionError->getAttributes();
            if (isset($attributes['message'])) {
                $error .= '<br />' . $attributes['message'];
            }
        }
        if ($name === 'debug_kit') {
            $error = 'Try adding your current <b>top level domain</b> to the
                <a href="https://book.cakephp.org/debugkit/5/configuration.html" target="_blank">DebugKit.safeTld</a>
            config and reload.';
            if (!in_array('sqlite', \PDO::getAvailableDrivers())) {
                $error .= '<br />You need to install the PHP extension <code>pdo_sqlite</code> so DebugKit can work properly.';
            }
        }
    }

    return compact('connected', 'error');
};

if (!Configure::read('debug')) :
    throw new NotFoundException(
        'Please replace templates/Pages/home.php with your own version or re-enable debug mode.'
    );
endif;

?>
<!DOCTYPE html>
<html>
<head>
    <?= $this->Html->charset() ?>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        CakePHP: the rapid development PHP framework:
        <?= $this->fetch('title') ?>
    </title>
    <?= $this->Html->meta('icon') ?>

    <?= $this->Html->css(['normalize.min', 'milligram.min', 'fonts', 'cake', 'home']) ?>

    <?= $this->fetch('meta') ?>
    <?= $this->fetch('css') ?>
    <?= $this->fetch('script') ?>
</head>
<body>
   <?php
$this->assign('title', 'Accueil');
?>

<style>
    .home-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 3rem 1rem;
        text-align: center;
        border-radius: 12px;
        margin-bottom: 2rem;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .home-header h1 { font-size: 2.5rem; margin-bottom: 0.5rem; font-weight: 700; }
    .home-header p { font-size: 1.1rem; opacity: 0.95; margin-bottom: 1rem; }
    .version {
        display: inline-block;
        background: rgba(255,255,255,0.2);
        padding: 0.5rem 1rem;
        border-radius: 20px;
        font-size: 0.9rem;
        margin-top: 0.5rem;
    }
    .status-badge {
        display: inline-block;
        padding: 0.4rem 0.8rem;
        background: #4caf50;
        color: white;
        border-radius: 20px;
        font-size: 0.85rem;
        font-weight: 600;
        margin-left: 0.5rem;
    }
    .nav-buttons {
        margin-top: 1.5rem;
        display: flex;
        gap: 1rem;
        justify-content: center;
        flex-wrap: wrap;
    }
    .nav-buttons a {
        display: inline-block;
        padding: 0.75rem 1.5rem;
        background: white;
        color: #667eea;
        text-decoration: none;
        border-radius: 25px;
        font-weight: 600;
        transition: transform 0.3s, box-shadow 0.3s;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }
    .nav-buttons a:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
    .nav-buttons a.primary { background: #667eea; color: white; }
    .nav-buttons a.primary:hover { background: #764ba2; }
    .ai-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        padding: 2rem;
        box-shadow: 0 8px 16px rgba(102, 126, 234, 0.3);
        margin-bottom: 2rem;
    }
    .ai-card h2 { font-size: 1.8rem; margin-bottom: 1rem; text-align: center; }
    .ai-features {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 1.5rem;
        margin: 1.5rem 0;
    }
    .ai-feature {
        background: rgba(255,255,255,0.15);
        padding: 1.2rem;
        border-radius: 8px;
        backdrop-filter: blur(10px);
    }
    .ai-feature h3 { font-size: 1.1rem; margin-bottom: 0.5rem; }
    .ai-feature p { font-size: 0.9rem; opacity: 0.95; margin: 0; }
    .ai-cta { text-align: center; margin-top: 1.5rem; }
    .ai-cta a {
        display: inline-block;
        padding: 1rem 2rem;
        background: white;
        color: #667eea;
        text-decoration: none;
        border-radius: 30px;
        font-weight: 700;
        font-size: 1.1rem;
        transition: transform 0.3s, box-shadow 0.3s;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }
    .ai-cta a:hover { transform: translateY(-3px); box-shadow: 0 6px 20px rgba(0,0,0,0.3); }
    .readme-toggle {
        background: white;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .readme-toggle summary {
        padding: 1.5rem 2rem;
        cursor: pointer;
        font-weight: 600;
        font-size: 1.2rem;
        color: #667eea;
        list-style: none;
        display: flex;
        justify-content: space-between;
        align-items: center;
        user-select: none;
    }
    .readme-toggle summary::-webkit-details-marker { display: none; }
    .readme-toggle summary::after { content: '▼'; transition: transform 0.3s; font-size: 0.8rem; }
    .readme-toggle[open] summary::after { transform: rotate(180deg); }
    .readme-toggle summary:hover { background: #f8f9fa; }
    .readme-toggle article { padding: 0 2rem 2rem; line-height: 1.8; }
    .readme-toggle article h1 {
        color: #667eea;
        font-size: 2rem;
        margin: 2rem 0 1rem;
        border-bottom: 3px solid #667eea;
        padding-bottom: 0.5rem;
    }
    .readme-toggle article h2 { color: #764ba2; font-size: 1.5rem; margin: 1.5rem 0 0.8rem; }
    .readme-toggle article code {
        background: #f4f4f4;
        padding: 0.2rem 0.4rem;
        border-radius: 3px;
        font-family: monospace;
        font-size: 0.9em;
        color: #d63384;
    }
    .readme-toggle article pre {
        background: #2d2d2d;
        color: #f8f8f2;
        padding: 1rem;
        border-radius: 5px;
        overflow-x: auto;
        margin: 1rem 0;
    }
    @media (max-width: 768px) {
        .home-header h1 { font-size: 1.8rem; }
        .nav-buttons { flex-direction: column; }
        .nav-buttons a { width: 100%; text-align: center; }
        .ai-features { grid-template-columns: 1fr; }
    }
</style>

<div class="home-header">
    <h1>🖼️ <?= $projectInfo['name']?></h1>
    <p><?= $projectInfo['description']?></p>
    <div class="version">
        Version <?= $projectInfo['version']?>
        <span class="status-badge">✓ Production Ready</span>
    </div>

    <div class="nav-buttons">
        <?= $this->Html->link('📷 Aller au Cropper', ['controller' => 'Uploads', 'action' => 'add'], ['class' => 'primary'])?>
        <?= $this->Html->link('📷 Interface Legacy', '/cropper.php', ['class' => 'primary'])?>
        <a href="https://github.com/b23prodtm/balena-photo-cropper" target="_blank">💻 GitHub</a>
    </div>
</div>

<div class="ai-card">
    <h2>✨ Restauration IA - Optimisé Raspberry Pi 2/3</h2>
    <div class="ai-features">
        <div class="ai-feature">
            <h3>🎨 Colorisation LUT</h3>
            <p>Redonnez des teintes naturelles aux photos N&B. Modèle léger 1Mo, instantané sur RPi, 0 swap.</p>
        </div>
        <div class="ai-feature">
            <h3>🌗 Mode HDR CLAHE</h3>
            <p>Débouchage automatique des ombres et récupération des hautes lumières. Traitement < 50ms.</p>
        </div>
        <div class="ai-feature">
            <h3>🤖 Upscale IA x4</h3>
            <p>Real-ESRGAN ncnn int8 : seulement 6Mo. Qualité pro, ~3min/photo sur RPi3. CPU only.</p>
        </div>
    <div class="ai-cta">
        <?= $this->Html->link('Lancer une restauration IA',
            ['controller' => 'Uploads', 'action' => 'add'])?>
    </div>
</div>

<details class="readme-toggle">
    <summary>📖 Documentation complète du projet</summary>
    <article>
<?php if (!empty($readmeHtml)):?>
        <div class="readme">
            <?= $readmeHtml?>
        </div>
<?php endif;?>
    </article>
</details>
</body>
</html>
