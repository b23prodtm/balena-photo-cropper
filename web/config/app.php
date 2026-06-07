<?php
return [
    'debug' => filter_var(env('DEBUG', true), FILTER_VALIDATE_BOOLEAN),
    'App' => [
        'namespace' => 'App',
        'encoding' => env('APP_ENCODING', 'UTF-8'),
        'base' => false,
        'baseUrl' => env('SCRIPT_NAME'),
        'dir' => 'src',
        'webroot' => 'webroot',
        'wwwRoot' => WWW_ROOT,
        'fullBaseUrl' => false,
        'imageBaseUrl' => 'img/',
        'jsBaseUrl' => 'js/',
        'cssBaseUrl' => 'css/',
        'paths' => [
            'plugins' => [ROOT . DS . 'plugins' . DS],
            'templates' => [APP . 'Template' . DS],
            'locales' => [APP . 'Locale' . DS],
        ],
    ],
    'Datasources' => [
        'default' => [
            'className' => 'Cake\Database\Connection',
            'driver' => 'Cake\Database\Driver\Mysql',
            'host' => env('DB_HOST', 'db'),
            'username' => env('DB_USER', 'cake_user'),
            'password' => function () {
                $file = '/run/secrets/DB_PASSWORD';
                return trim(file_exists($file) ? file_get_contents($file) : '');
            },
            'database' => env('DB_NAME', 'cake_db'),
            'port' => '3306',
            'encoding' => 'utf8mb4',
            'timezone' => 'UTC',
        ],
    ],
];