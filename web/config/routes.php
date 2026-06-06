<?php
use Cake\Routing\Route\DashedRoute;
use Cake\Routing\RouteBuilder;

return function (RouteBuilder $routes): void {
    $routes->setRouteClass(DashedRoute::class);

    $routes->scope('/', function (RouteBuilder $builder): void {
        // Accueil
        $builder->connect('/', ['controller' => 'Pages', 'action' => 'display', 'home']);

        // Uploads + API
        $builder->connect('/cropper', ['controller' => 'Uploads', 'action' => 'cropper']);
        $builder->connect('/uploads/add', ['controller' => 'Uploads', 'action' => 'add']);
        $builder->connect('/uploads', ['controller' => 'Uploads', 'action' => 'index']);
        
        // API endpoints pour CropperJS
        $builder->connect('/uploads/upload', ['controller' => 'Uploads', 'action' => 'upload']);
        $builder->connect('/uploads/save-crop', ['controller' => 'Uploads', 'action' => 'saveCrop']);
        $builder->connect('/uploads/crop', ['controller' => 'Uploads', 'action' => 'crop']);

        // Legacy redirect
        $builder->redirect('/cropper.php', '/cropper', ['status' => 301]);

        $builder->fallbacks();
    });
};