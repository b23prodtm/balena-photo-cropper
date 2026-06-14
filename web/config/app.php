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
            'persistent' => false,
            'host' => env('DB_HOST', 'db'),
            'username' => env('DB_USER', 'cake_user'),
            'password' => file_get_contents(env('DB_PASSWORD_FILE', '/run/secrets/DB_PASSWORD')),
            'database' => env('DB_NAME', 'cake_db'),
            'port' => '3306',
        ],
    ],
];