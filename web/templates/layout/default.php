<?php
/**
 * @var \App\View\AppView $this
 */
$cakeDescription = 'Balena Photo Cropper';
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <?= $this->Html->charset() ?>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <?= $cakeDescription ?>: <?= $this->fetch('title') ?>
    </title>
    <?= $this->Html->meta('icon') ?>

    <!-- Ton CSS global ici -->
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .main-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .main-header nav {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .main-header a {
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            transition: background 0.3s;
        }

        .main-header a:hover {
            background: rgba(255,255,255,0.2);
        }

        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 1rem;
            flex: 1;
        }

        .flash-message {
            padding: 1rem;
            margin-bottom: 1rem;
            border-radius: 4px;
        }

        .flash-message.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .flash-message.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        .main-footer {
            text-align: center;
            padding: 2rem;
            background: #2d2d2d;
            color: #999;
            margin-top: auto;
        }

        @media (prefers-color-scheme: dark) {
            body {
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                color: #e0e0e0;
            }
        }
    </style>

    <?= $this->fetch('meta') ?>
    <?= $this->fetch('css') ?>
    <?= $this->fetch('script') ?>
</head>
<body>
    <header class="main-header">
        <nav>
            <div>
                <?= $this->Html->link('🖼️ Photo Cropper', '/', ['style' => 'font-size: 1.3rem; font-weight: 700;']) ?>
            </div>
            <div>
                <?= $this->Html->link('Accueil', '/') ?>
                <?= $this->Html->link('Cropper', ['controller' => 'Uploads', 'action' => 'add']) ?>
                <a href="https://github.com/b23prodtm/balena-photo-cropper" target="_blank">GitHub</a>
            </div>
        </nav>
    </header>

    <div class="container">
        <?= $this->Flash->render() ?>
        <?= $this->fetch('content') ?>
    </div>

    <footer class="main-footer">
        <p>🐳 Déployé avec Docker Compose | ⚡ CakePHP & OpenCV | 🔧 Bruno (b23prodtm)</p>
        <p style="margin-top: 0.5rem; font-size: 0.9rem;">© 2026 Photo Cropper</p>
    </footer>
</body>
</html>