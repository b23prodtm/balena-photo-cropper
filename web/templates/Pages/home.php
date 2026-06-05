<?php
/**
 * CakePHP Template - HomePage
 *
 * Location: templates/Pages/home.php
 *
 * Affiche le README du projet avec un template CakePHP moderne
 */
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $projectInfo['name']?> - <?= $projectInfo['description']?></title>
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
        }

        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 3rem 1rem;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
            font-weight: 700;
        }

        header p {
            font-size: 1.1rem;
            opacity: 0.95;
            margin-bottom: 1rem;
        }

       .version {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 0.5rem;
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

       .nav-buttons a:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }

       .nav-buttons a.primary {
            background: #667eea;
            color: white;
        }

       .nav-buttons a.primary:hover {
            background: #764ba2;
        }

        /* SECTION IA */
       .ai-banner {
            max-width: 900px;
            margin: -1rem auto 2rem;
            padding: 0 1rem;
        }

       .ai-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 8px 16px rgba(102, 126, 234, 0.3);
        }

       .ai-card h2 {
            font-size: 1.8rem;
            margin-bottom: 1rem;
            text-align: center;
        }

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

       .ai-feature h3 {
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
        }

       .ai-feature p {
            font-size: 0.9rem;
            opacity: 0.95;
            margin: 0;
        }

       .ai-cta {
            text-align: center;
            margin-top: 1.5rem;
        }

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

       .ai-cta a:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.3);
        }

        main {
            max-width: 900px;
            margin: 2rem auto;
            padding: 0 1rem;
        }

        /* README EN SOUS-RUBRIQUE */
       .readme-toggle {
            background: white;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
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

       .readme-toggle summary::-webkit-details-marker {
            display: none;
        }

       .readme-toggle summary::after {
            content: '▼';
            transition: transform 0.3s;
            font-size: 0.8rem;
        }

       .readme-toggle[open] summary::after {
            transform: rotate(180deg);
        }

       .readme-toggle summary:hover {
            background: #f8f9fa;
        }

        article {
            padding: 0 2rem 2rem;
            line-height: 1.8;
        }

        article h1 {
            color: #667eea;
            font-size: 2rem;
            margin: 2rem 0 1rem;
            border-bottom: 3px solid #667eea;
            padding-bottom: 0.5rem;
        }

        article h2 {
            color: #764ba2;
            font-size: 1.5rem;
            margin: 1.5rem 0 0.8rem;
        }

        article h3 {
            color: #999;
            font-size: 1.2rem;
            margin: 1.2rem 0 0.6rem;
        }

        article h4,
        article h5,
        article h6 {
            margin: 1rem 0 0.5rem;
            color: #666;
        }

        article p {
            margin: 1rem 0;
            text-align: justify;
        }

        article ul,
        article ol {
            margin: 1rem 0 1rem 2rem;
        }

        article li {
            margin: 0.5rem 0;
        }

        article a {
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
            border-bottom: 1px solid transparent;
            transition: border-color 0.3s;
        }

        article a:hover {
            border-bottom-color: #667eea;
        }

        article code {
            background: #f4f4f4;
            padding: 0.2rem 0.4rem;
            border-radius: 3px;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            color: #d63384;
        }

        article pre {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 1rem;
            border-radius: 5px;
            overflow-x: auto;
            margin: 1rem 0;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.9rem;
            line-height: 1.4;
        }

        article pre code {
            background: none;
            padding: 0;
            color: inherit;
        }

        article table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        article table th,
        article table td {
            padding: 0.75rem;
            text-align: left;
            border: 1px solid #e0e0e0;
        }

        article table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #667eea;
        }

        article table tr:hover {
            background: #f9f9f9;
        }

       .status-badge {
            display: inline-block;
            padding: 0.4rem 0.8rem;
            background: #4caf50;
            color: white;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            margin: 0.5rem 0;
        }

        blockquote {
            border-left: 4px solid #667eea;
            padding-left: 1rem;
            margin: 1rem 0;
            color: #666;
            font-style: italic;
        }

        footer {
            text-align: center;
            padding: 2rem;
            color: #666;
            margin-top: 2rem;
            border-top: 1px solid #e0e0e0;
        }

       .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 1.5rem 0;
        }

       .feature-card {
            background: #f8f9fa;
            padding: 1.5rem;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }

       .feature-card strong {
            color: #667eea;
        }

        @media (max-width: 768px) {
            header h1 {
                font-size: 1.8rem;
            }

            header p {
                font-size: 1rem;
            }

            article {
                padding: 0 1.5rem 1.5rem;
            }

            article h1 {
                font-size: 1.5rem;
            }

            article h2 {
                font-size: 1.2rem;
            }

           .nav-buttons {
                flex-direction: column;
            }

           .nav-buttons a {
                width: 100%;
                text-align: center;
            }

           .feature-grid {
                grid-template-columns: 1fr;
            }

           .ai-features {
                grid-template-columns: 1fr;
            }
        }

        @media (prefers-color-scheme: dark) {
            body {
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                color: #e0e0e0;
            }

           .readme-toggle {
                background: #2a2a3e;
            }

           .readme-toggle summary:hover {
                background: #3a3a4e;
            }

            article h1,
            article h2,
            article h3 {
                color: #8ba1ff;
            }

            article code {
                background: #3a3a4e;
                color: #ff6b9d;
            }

            article pre {
                background: #1a1a2e;
                color: #e0e0e0;
            }

            article table {
                background: #2a2a3e;
            }

            article table th {
                background: #3a3a4e;
                color: #8ba1ff;
            }

            article a {
                color: #8ba1ff;
            }

           .feature-card {
                background: #3a3a4e;
            }

            footer {
                color: #999;
                border-top-color: #3a3a4e;
            }
        }
    </style>
</head>
<body>
    <header>
        <h1>🖼️ <?= $projectInfo['name']?></h1>
        <p><?= $projectInfo['description']?></p>
        <div class="version">
            Version <?= $projectInfo['version']?>
            <span class="status-badge">✓ Production Ready</span>
        </div>

        <div class="nav-buttons">
            <a href="/cropper" class="primary">📷 Aller au Cropper</a>
            <a href="/cropper.php" class="primary">📷 Interface Legacy</a>
            <a href="https://github.com/b23prodtm/balena-photo-cropper" target="_blank">💻 GitHub</a>
        </div>
    </header>

    <!-- SECTION IA EN PREMIER -->
    <section class="ai-banner">
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
            </div>
            <div class="ai-cta">
                <?= $this->Html->link('Lancer une restauration IA',
                    ['controller' => 'Uploads', 'action' => 'add'],
                    ['class' => 'ai-button'])?>
            </div>
        </div>
    </section>

    <main>
        <!-- README EN SOUS-RUBRIQUE REPLIABLE -->
        <details class="readme-toggle">
            <summary>📖 Documentation complète du projet</summary>
            <article>
                <?php echo $readmeHtml;?>
            </article>
        </details>
    </main>

    <footer>
        <p>
            🐳 Déployé avec Docker Compose |
            ⚡ Alimenté par CakePHP & OpenCV |
            🔧 Maintenu par <strong>Bruno (b23prodtm)</strong>
        </p>
        <p style="margin-top: 0.5rem; font-size: 0.9rem;">
            © 2026 Photo Cropper. All rights reserved.
        </p>
    </footer>
</body>
</html>