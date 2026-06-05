<?php
declare(strict_types=1);

namespace App\Controller;

use Cake\Http\Client;
use Cake\Http\Exception\BadRequestException;
use Cake\Http\Exception\MethodNotAllowedException;

class UploadsController extends AppController
{
    public function initialize(): void
    {
        parent::initialize();
        // Désactive CSRF pour les endpoints API
        $this->loadComponent('FormProtection', [
            'unlockedActions' => ['upload', 'saveCrop', 'crop']
        ]);
    }

    /**
     * Interface CropperJS - GET /cropper
     */
    public function cropper()
    {
        $this->viewBuilder()->setLayout('default');
    }

    /**
     * Upload + traitement IA complet - GET/POST /uploads/add
     */
    public function add()
    {
        if ($this->request->is('post')) {
            $file = $this->request->getData('scan_file');
            $options = $this->request->getData('options', []);

            if (!$file || $file->getError() !== UPLOAD_ERR_OK) {
                $this->Flash->error(__('Erreur lors de l\'upload du fichier.'));
                return;
            }

            $uploadPath = WWW_ROOT . 'uploads' . DS;
            if (!is_dir($uploadPath)) {
                mkdir($uploadPath, 0777, true);
            }
            
            $filename = time() . '_' . $file->getClientFilename();
            $targetPath = $uploadPath . $filename;
            $file->moveTo($targetPath);

            try {
                $http = new Client(['timeout' => 900]);
                $response = $http->post('http://cropper:5000/process', [
                    'multipart' => [
                        [
                            'name' => 'scan',
                            'contents' => fopen($targetPath, 'r'),
                            'filename' => $filename
                        ],
                        [
                            'name' => 'options',
                            'contents' => json_encode($options)
                        ]
                    ]
                ]);

                $result = $response->getJson();
                $count = count($result['files'] ?? []);
                
                $this->Flash->success(__('Traitement terminé : {0} photos extraites.', $count));
                return $this->redirect(['action' => 'index']);
                
            } catch (\Exception $e) {
                $this->Flash->error(__('Erreur traitement : {0}', $e->getMessage()));
            }
        }
    }

    /**
     * API Upload simple - POST /uploads/upload
     * Pour CropperJS
     */
    public function upload()
    {
        $this->request->allowMethod(['post']);
        $this->viewBuilder()->setClassName('Json');

        $file = $this->request->getData('file');
        if (!$file) {
            return $this->response->withType('application/json')
                ->withStringBody(json_encode(['success' => false, 'error' => 'No file']));
        }

        $filename = uniqid() . '_' . $file->getClientFilename();
        $target = WWW_ROOT . 'uploads' . DS . $filename;
        $file->moveTo($target);

        return $this->response->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'pages' => ['/uploads/' . $filename]
            ]));
    }

    /**
     * API Save Crop - POST /uploads/save-crop
     * Pour CropperJS
     */
    public function saveCrop()
    {
        $this->request->allowMethod(['post']);
        $this->viewBuilder()->setClassName('Json');

        $file = $this->request->getData('crop');
        if (!$file) {
            return $this->response->withType('application/json')
                ->withStringBody(json_encode(['success' => false]));
        }

        $filename = 'crop_' . uniqid() . '.jpg';
        $target = WWW_ROOT . 'uploads' . DS . $filename;
        $file->moveTo($target);

        return $this->response->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'file' => '/uploads/' . $filename
            ]));
    }

    /**
     * Proxy vers service Python - POST /uploads/crop
     */
    public function crop()
    {
        if (!$this->request->is('post')) {
            throw new MethodNotAllowedException();
        }

        $this->viewBuilder()->setClassName('Json');
        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        try {
            $client = new Client();
            $response = $client->post($cropperServiceUrl . '/crop', [
                'json' => $this->request->getData(),
                'timeout' => 60
            ]);
            
            return $this->response
                ->withStatus($response->getStatusCode())
                ->withType('application/json')
                ->withStringBody($response->getStringBody());
        } catch (\Exception $e) {
            $this->log('Crop operation failed: ' . $e->getMessage(), 'error');
            return $this->response
                ->withStatus(500)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Crop operation failed',
                    'message' => $e->getMessage()
                ]));
        }
    }

    /**
     * Liste des uploads - GET /uploads
     */
    public function index()
    {
        $uploadsDir = WWW_ROOT . 'uploads' . DS;
        $files = glob($uploadsDir . '*.{jpg,jpeg,png,pdf}', GLOB_BRACE) ?: [];
        $this->set('files', array_map('basename', $files));
    }
}