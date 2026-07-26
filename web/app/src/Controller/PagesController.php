<?php
declare(strict_types=1);

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
 * @since     0.2.9
 * @license   https://opensource.org/licenses/mit-license.php MIT License
 */
namespace App\Controller;

use Cake\Core\Configure;
use Cake\Http\Exception\ForbiddenException;
use Cake\Http\Exception\NotFoundException;
use Cake\Http\Response;
use Cake\View\Exception\MissingTemplateException;

/**
 * Static content controller
 *
 * This controller will render views from templates/Pages/
 *
 * @link https://book.cakephp.org/5/en/controllers/pages-controller.html
 */
class PagesController extends AppController
{
    /**
     * Displays a view
     *
     * @param string ...$path Path segments.
     * @return \Cake\Http\Response|null
     * @throws \Cake\Http\Exception\ForbiddenException When a directory traversal attempt.
     * @throws \Cake\View\Exception\MissingTemplateException When the view file could not
     *   be found and in debug mode.
     * @throws \Cake\Http\Exception\NotFoundException When the view file could not
     *   be found and not in debug mode.
     * @throws \Cake\View\Exception\MissingTemplateException In debug mode.
     */
    public function display(string...$path):?Response
    {
        if (!$path) {
            return $this->redirect('/');
        }
        if (in_array('..', $path, true) || in_array('.', $path, true)) {
            throw new ForbiddenException();
        }

        $page = $subpage = null;
        if (!empty($path[0])) {
            $page = $path[0];
        }
        if (!empty($path[1])) {
            $subpage = $path[1];
        }

        // Données pour la home
        if ($page === 'home') {
            $projectInfo = [
                'name' => 'Balena Photo Cropper',
                'description' => 'Scanne, découpe et restaure tes photos argentiques avec IA',
                'version' => '1.0.0',
                'features' => [
                    'Détection auto des photos',
                    'Crop manuel CropperJS',
                    'Restauration IA : colorisation, HDR, upscale x4',
                    'Optimisé Raspberry Pi 2/3'
                ]
            ];

            // Parse README.md si présent, sinon vide
            $readmePath = ROOT. DS. 'README.md';
            $readmeHtml = '';

            if (file_exists($readmePath)) {
                $readme = file_get_contents($readmePath);
                $readmeHtml = $this->parseMarkdown($readme);
            }

            $this->set(compact('projectInfo', 'readmeHtml'));
        }

        $this->set(compact('page', 'subpage'));

        try {
            return $this->render(implode('/', $path));
        } catch (MissingTemplateException $exception) {
            if (Configure::read('debug')) {
                throw $exception;
            }
            throw new NotFoundException();
        }
    }

    /**
     * Parse simple markdown to HTML
     */
    private function parseMarkdown(string $markdown): string
    {
        $html = preg_replace('/^# (.+)$/m', '<h1>$1</h1>', $markdown);
        $html = preg_replace('/^## (.+)$/m', '<h2>$1</h2>', $html);
        $html = preg_replace('/^### (.+)$/m', '<h3>$1</h3>', $html);
        $html = preg_replace('/^#### (.+)$/m', '<h4>$1</h4>', $html);
        $html = preg_replace('/^- (.+)$/m', '<li>$1</li>', $html);
        $html = preg_replace('/(<li>.+<\/li>)/s', '<ul>$1</ul>', $html);
        $html = preg_replace('/```(.+?)```/s', '<pre><code>$1</code></pre>', $html);
        $html = preg_replace('/`(.+?)`/', '<code>$1</code>', $html);
        $html = preg_replace('/\[(.+?)\]\((.+?)\)/', '<a href="$2" target="_blank">$1</a>', $html);

        $lines = explode("\n", $html);
        $inCode = false;
        $inList = false;
        $result = [];

        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line)) {
                $result[] = '';
                continue;
            }

            if (strpos($line, '<pre><code>')!== false) $inCode = true;
            if (strpos($line, '</code></pre>')!== false) $inCode = false;
            if (strpos($line, '<ul>')!== false) $inList = true;
            if (strpos($line, '</ul>')!== false) $inList = false;

            if (!$inCode &&!$inList &&
              !preg_match('/^<h[1-6]|^<p|^<ul|^<li|^<pre|^<code|^<a/', $line) &&
              !empty($line)) {
                $line = '<p>'. $line. '</p>';
            }

            $result[] = $line;
        }

        return implode("\n", $result);
    }
}
