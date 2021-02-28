# Docker for php-fpm, laravel and nginx

![](docker.svg)

## Laravel

~~~zsh
% phpenv versions
  system
* 7.4.9 (set by /Users/hdknr/.anyenv/envs/phpenv/version)

% which composer
/Users/hdknr/.anyenv/envs/phpenv/shims/compose

% composer global require laravel/installer
% phpenv rehash

% laravel --version
Laravel Installer 4.1.1

% laravel new lvdocker
~~~

check:

~~~zsh
% php artisan serve --host 0.0.0.0
Starting Laravel development server: http://0.0.0.0:8000
[Sat Feb 27 21:30:55 2021] PHP 7.4.9 Development Server (http://0.0.0.0:8000) started
~~~

### Logging: `/dev/stdout`


config/logging.php:

~~~php
<?php
use Monolog\Handler\NullHandler;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogUdpHandler;

return [
    'channels' => [
        ....,
        'stdout' => [
            'driver' => 'monolog',
            'handler' => StreamHandler::class,
            'with' => [
                'stream' => 'php://stdout',
            ],
        ],
    ],
];
~~~

.env:

~~~ini
LOG_CHANNEL=stdout
~~~

## php-fpm

/usr/local/etc/php-fpm.d/app.conf:

~~~ini
[global]

[www]
user = www-data
group = www-data
listen.owner = www-data
listen.group = www-data

listen = var/run/upstream.php-fpm.sock
listen.allowed_clients = 127.0.0.1
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
~~~

~~~bash
% php-fpm --nodaemonize  -y /usr/local/etc/php-fpm.d/app.conf
~~~


## nginx

/etc/nginx/sites-enabled/default:

~~~conf
upstream app {
    server unix:/usr/local/var/run/upstream.php-fpm.sock;
}

server {
    listen 80 default_server;
    server_name localhost;
    index index.php index.html;
    root /var/www/html/public;

    access_log /dev/stdout;
    error_log /dev/stdout warn;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}
~~~