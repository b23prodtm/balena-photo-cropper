<?php
declare(strict_types=1);

namespace App\Controller;

use Cake\Http\Client;
use Cake\Http\Exception\BadRequestException;

class UploadsController extends AppController
{
    /**
     * Interface CropperJS - GET /cropper
     */
    public function cropper()
    {
        $this->viewBuilder()->setLayout('default');
    }

    /**
     * Upload + traitement IA - GET/POST /uploads/add
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

            // Sauvegarde locale
            $uploadPath = WWW_ROOT . 'uploads' . DS;
            if (!is_dir($uploadPath)) {
                mkdir($uploadPath, 0777, true);
            }
            
            $filename = time() . '_' . $file->getClientFilename();
            $targetPath = $uploadPath . $filename;
            $file->moveTo($targetPath);

            // Appel service cropper Python
            try {
                $http = new Client([
                    'timeout' => 900 // 15min pour upscale IA x4
                ]);

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

                if ($response->getStatusCode() !== 200) {
                    throw new \Exception('Service cropper indisponible');
                }

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
     * Liste des uploads - GET /uploads
     */
    public function index()
    {
        $uploadsDir = WWW_ROOT . 'uploads' . DS;
        $files = glob($uploadsDir . '*.{jpg,jpeg,png,pdf}', GLOB_BRACE) ?: [];
        $this->set('files', array_map('basename', $files));
    }
}