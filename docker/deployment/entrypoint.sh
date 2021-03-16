service ssh restart
service nginx restart
php-fpm -F -O  -y /usr/local/etc/php-fpm.d/app.conf