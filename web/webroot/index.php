<?php
declare(strict_types=1);

use Cake\Http\Server;

require dirname(__DIR__). '/vendor/autoload.php';

use App\Application;

$server = new Server(new Application(dirname(__DIR__). '/config'));
$server->emit($server->run());