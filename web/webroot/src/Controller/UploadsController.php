<?php
declare(strict_types=1);

namespace App\Controller;

use Cake\Http\Client;
use Cake\Http\Exception\BadRequestException;

class UploadsController extends AppController
{
    public function add()
    {
        if ($this->request->is('post')) {
            $file = $this->request->getData('scan_file');
            $options = $this->request->getData('options', []);

            if ($file->getError() !== UPLOAD_ERR_OK) {
                throw new BadRequestException('Erreur upload');
            }

            $targetPath = WWW_ROOT . 'uploads' . DS . $file->getClientFilename();
            $file->moveTo($targetPath);

            $http = new Client(['timeout' => 900]);
            $response = $http->post('http://cropper:5000/process', [
                'multipart' => [
                    ['name' => 'scan', 'contents' => fopen($targetPath, 'r'), 'filename' => $file->getClientFilename()],
                    ['name' => 'options', 'contents' => json_encode($options)]
                ]
            ]);

            $result = $response->getJson();
            $this->Flash->success(__('Traitement terminé : {0} photos extraites.', count($result['files'])));
            return $this->redirect(['action' => 'index']);
        }
    }
}