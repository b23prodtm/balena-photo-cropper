<?php
/**
 * CakePHP3 Cropper Index Controller
 * Routes requests from /cropper.php to the Python cropper service
 * 
 * Location: src/Controller/CropperController.php
 */

namespace App\Controller;

use Cake\Controller\Controller;

class CropperController extends Controller
{
    public function initialize()
    {
        parent::initialize();
        // Disable CSRF for API endpoints if needed
        // $this->FormProtection->setConfig('unlockedActions', ['crop']);
    }

    /**
     * Index action - displays the cropper interface
     * Proxies to the Python cropper service running on localhost:5000
     */
    public function index()
    {
        // Get the Python service endpoint from environment or use default
        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        // Forward the request to the Python cropper service
        $client = new \Cake\Http\Client();
        
        try {
            // Check if it's an API call or interface request
            if ($this->request->is('post')) {
                // Forward POST requests (crop operations) to the service
                $response = $client->post($cropperServiceUrl . '/crop', [
                    'json' => $this->request->getData(),
                    'timeout' => 30
                ]);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withType('application/json')
                    ->withStringBody($response->getStringBody());
            } else {
                // GET request - serve the cropper interface
                $response = $client->get($cropperServiceUrl);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withStringBody($response->getStringBody());
            }
        } catch (\Exception $e) {
            $this->log('Cropper service error: ' . $e->getMessage(), 'error');
            
            return $this->response
                ->withStatus(503)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Cropper service unavailable',
                    'message' => $e->getMessage()
                ]));
        }
    }

    /**
     * Crop action - handles image cropping operations
     * POST /cropper/crop with image data
     */
    public function crop()
    {
        if (!$this->request->is('post')) {
            return $this->response
                ->withStatus(405)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'Method not allowed']));
        }

        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        try {
            $client = new \Cake\Http\Client();
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
     * Upload action - handles image uploads
     * POST /cropper/upload with multipart form data
     */
    public function upload()
    {
        if (!$this->request->is('post')) {
            return $this->response
                ->withStatus(405)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'Method not allowed']));
        }

        $cropperServiceUrl = env('CROPPER_SERVICE_URL', 'http://cropper:5000');
        
        try {
            // Forward file upload to Python service
            $client = new \Cake\Http\Client();
            
            // Build multipart request with file
            $files = $this->request->getUploadedFiles();
            if (!empty($files['image'])) {
                $file = $files['image'];
                
                // Read file content
                $fileContent = file_get_contents($file->getStream()->getMetadata('uri'));
                
                $response = $client->post($cropperServiceUrl . '/upload', [
                    'multipart' => [
                        [
                            'name' => 'image',
                            'contents' => $fileContent,
                            'filename' => $file->getClientFilename()
                        ]
                    ]
                ]);
                
                return $this->response
                    ->withStatus($response->getStatusCode())
                    ->withType('application/json')
                    ->withStringBody($response->getStringBody());
            }
            
            return $this->response
                ->withStatus(400)
                ->withType('application/json')
                ->withStringBody(json_encode(['error' => 'No image file provided']));
        } catch (\Exception $e) {
            $this->log('Upload failed: ' . $e->getMessage(), 'error');
            
            return $this->response
                ->withStatus(500)
                ->withType('application/json')
                ->withStringBody(json_encode([
                    'error' => 'Upload failed',
                    'message' => $e->getMessage()
                ]));
        }
    }
}
