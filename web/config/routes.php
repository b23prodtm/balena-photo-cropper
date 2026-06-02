<?php
/**
 * CakePHP3 Routes Configuration
 * File: config/routes.php
 * 
 * Add these route definitions to your routes configuration
 */

// Cropper interface and API routes
$routes->scope('/cropper', ['controller' => 'Cropper'], function ($routes) {
    // Main cropper interface
    $routes->connect('/', ['action' => 'index']);
    
    // API endpoints
    $routes->connect('/crop', ['action' => 'crop']);
    $routes->connect('/upload', ['action' => 'upload']);
    
    // RESTful API support
    $routes->resources('Cropper');
});

// Legacy support for /cropper.php (rewrite to /cropper)
$routes->connect('/cropper.php', ['controller' => 'Cropper', 'action' => 'index']);

// Homepage redirect logic
$routes->connect('/', function($builder) {
    return [
        'controller' => 'Pages',
        'action' => 'home'  // or redirect to cropper: ['controller' => 'Cropper', 'action' => 'index']
    ];
});

// Default fallback
$routes->fallbacks(DashedRoute::class);