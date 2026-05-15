<?php
namespace App\Controller;

use Cake\Controller\Controller;

class ApiController extends Controller
{
    public function cropper()
    {
    }

    public function upload()
    {
        $this->request->allowMethod(['post']);

        $file = $this->request->getData('file');

        if (!$file) {
            return $this->response
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'success' => false
                ]));
        }

        $filename = uniqid() . '_' . $file->getClientFilename();

        $target = WWW_ROOT . 'uploads/' . $filename;

        $file->moveTo($target);

        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'pages' => [
                    '/uploads/' . $filename
                ]
            ]));
    }

    public function saveCrop()
    {
        $this->request->allowMethod(['post']);

        $file = $this->request->getData('crop');

        $filename = 'crop_' . uniqid() . '.jpg';

        $target = WWW_ROOT . 'uploads/' . $filename;

        $file->moveTo($target);

        return $this->response
            ->withType('application/json')
            ->withStringBody(json_encode([
                'success' => true,
                'file' => '/uploads/' . $filename
            ]));
    }
}
