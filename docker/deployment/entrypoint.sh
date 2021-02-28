service ssh restart
service nginx restart
php-fpm --nodaemonize  -y /usr/local/etc/php-fpm.d/app.conf