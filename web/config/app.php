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
];