<?php
define('ROOT', dirname(__DIR__));
define('APP_DIR', 'src');
define('WEBROOT_DIR', 'webroot');
define('APP', ROOT . DS . APP_DIR . DS);
define('TMP', ROOT . DS . 'tmp' . DS);
define('LOGS', ROOT . DS . 'logs' . DS);
define('CACHE', ROOT . DS . 'tmp' . DS . 'cache' . DS);
define('CAKE_CORE_INCLUDE_PATH', ROOT . DS . 'vendor' . DS . 'cakephp' . DS . 'cakephp' . DS . 'src');
define('CORE_PATH', CAKE_CORE_INCLUDE_PATH . DS);
define('WWW_ROOT', ROOT . DS . WEBROOT_DIR . DS);

if (!defined('DS')) {
    define('DS', DIRECTORY_SEPARATOR);
}

require ROOT . DS . 'vendor' . DS . 'cakephp' . DS . 'cakephp' . DS . 'src' . DS . 'functions.php';
require ROOT . DS . 'vendor' . DS . 'autoload.php';