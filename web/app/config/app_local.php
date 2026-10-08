<?php

use function Cake\Core\env;

/*
 * Read secret/config from KEY_FILE or KEY.
 * Priority: KEY_FILE -> KEY -> default.
 */
if (!function_exists('env_or_file')) {
    function env_or_file(string $key, $default = null)
    {
        $file = env($key . '_FILE', null);
        if ($file && is_readable($file)) {
            $value = trim((string)file_get_contents($file));
            return $value !== '' ? $value : $default;
        }

        $value = env($key, null);
        return $value !== null ? $value : $default;
    }
}

/*
 * Local configuration file to provide any overrides to your app.php configuration.
 * Copy and save this file as app_local.php and make changes as required.
 * Note: It is not recommended to commit files with credentials such as app_local.php
 * into source code version control.
 */
return [
    /*
     * Debug Level:
     *
     * Production Mode:
     * false: No error messages, errors, or warnings shown.
     *
     * Development Mode:
     * true: Errors and warnings shown.
     */
    'debug' => filter_var(env('DEBUG', false), FILTER_VALIDATE_BOOLEAN),

    /*
     * Security and encryption configuration
     *
     * - salt - A random string used in security hashing methods.
     *   The salt value is also used as the encryption key.
     *   You should treat it as extremely sensitive data.
     */
    'Security' => [
        'salt' => env_or_file('SECURITY_SALT', '__SALT__'),
    ],

    /*
     * Connection information used by the ORM to connect
     * to your application's datastores.
     *
     * See app.php for more configuration options.
     */
    'Datasources' => [
        'default' => [
            'host' => env('DB_HOST', 'localhost'),
            /*
             * CakePHP will use the default DB port based on the driver selected
             * MySQL on MAMP uses port 8889, MAMP users will want to uncomment
             * the following line and set the port accordingly
             */
            'port' => env('DB_PORT', 3306),

            'username' => env('DB_USER', 'my_app'),
            'password' => env_or_file('DB_PASSWORD', 'secret'),

            'database' => env('DB_NAME', 'my_app'),
            /*
             * If not using the default 'public' schema with the PostgreSQL driver
             * set it here.
             */
            //'schema' => 'myapp',

            /*
             * You can use a DSN string to set the entire configuration
             */
            'url' => env('DATABASE_URL', null),
        ],

        /*
         * The test connection is used during the test suite.
         */
        'test' => [
            'host' => env('DB_TEST_HOST', 'localhost'),
            //'port' => 'non_standard_port_number',
            'username' => env('DB_TEST_USERNAME', 'my_app'),
            'password' => env_or_file('DB_TEST_PASSWORD', 'secret'),
            'database' => env('DB_TEST_DATABASE', 'test_myapp'),
            //'schema' => 'myapp',
            'url' => env('DATABASE_TEST_URL', 'sqlite://127.0.0.1/tmp/tests.sqlite'),
        ],
    ],

    /*
     * Email configuration.
     *
     * Host and credential configuration in case you are using SmtpTransport
     *
     * See app.php for more configuration options.
     */
    'EmailTransport' => [
        'default' => [
            'host' => env('EMAIL_HOST', 'localhost'),
            'port' => (int)env('EMAIL_PORT', 25),
            'username' => env('EMAIL_USERNAME', null),
            'password' => env_or_file('EMAIL_PASSWORD', null),
            'client' => env('EMAIL_CLIENT', null),
            'url' => env('EMAIL_TRANSPORT_DEFAULT_URL', null),
        ],
    ],

    /*
     * Logging configuration.
     * Keep file logs for Cake and also allow Docker/Balena stderr capture from PHP-FPM.
     */
    'Log' => [
        'debug' => [
            'className' => \Cake\Log\Engine\FileLog::class,
            'path' => LOGS,
            'file' => 'debug',
            'levels' => ['notice', 'info', 'debug'],
            'url' => env('LOG_DEBUG_URL', null),
        ],
        'error' => [
            'className' => \Cake\Log\Engine\FileLog::class,
            'path' => LOGS,
            'file' => 'error',
            'levels' => ['warning', 'error', 'critical', 'alert', 'emergency'],
            'url' => env('LOG_ERROR_URL', null),
        ],
    ],
];
