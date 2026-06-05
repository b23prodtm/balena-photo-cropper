<?php
use Cake\Routing\Route\DashedRoute;
use Cake\Routing\RouteBuilder;

return function (RouteBuilder $routes): void {
    $routes->setRouteClass(DashedRoute::class);

    $routes->scope('/', function (RouteBuilder $builder): void {
        // Page d'accueil avec section IA + README
        $builder->connect('/', ['controller' => 'Pages', 'action' => 'display', 'home']);

        // Interface CropperJS
        $builder->connect('/cropper', ['controller' => 'Uploads', 'action' => 'cropper']);
        
        // Upload + traitement IA
        $builder->connect('/uploads/add', ['controller' => 'Uploads', 'action' => 'add']);

        // Legacy : /cropper.php redirige vers /cropper
        $builder->redirect('/cropper.php', ['controller' => 'Uploads', 'action' => 'cropper'], ['status' => 301]);

        // Fallback
        $builder->fallbacks();
    });
};