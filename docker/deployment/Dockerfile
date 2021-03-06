ARG BUILD_ARG_ENV
#

FROM node:14 as assets
WORKDIR /var/www/html

###########################################
## node
COPY package.json package-lock.json semantic.json ./
COPY semantic ./semantic/
RUN npm install 
COPY resources ./resources/
COPY webpack.config.js webpack.mix.js ./
RUN npm run production

FROM php:8-fpm

############################################
## Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


############################################
## SSH
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

## --- SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir ~/.ssh
COPY ./docker/deployment/ssh/hdknr.pub /root/.ssh/authorized_keys
# RUN echo $SSH_PUBLIC_KEY >> ~/.ssh/authorized_keys
RUN chmod 0600 /root/.ssh/authorized_keys

############################################
## nginx
RUN apt-get install nginx -y
COPY ./docker/deployment/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default

############################################
## PHP Laravel

# Install dependencies and clean cache
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# php-fpm.conf
COPY ./docker/deployment/php/app.conf /usr/local/etc/php-fpm.d/app.conf

# Install extensions
RUN docker-php-ext-install pdo_mysql

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
COPY composer.lock composer.json /var/www/html/
RUN composer install --no-autoloader

# app
COPY --chown=www-data:www-data . /var/www/html
COPY --from=assets /var/www/html/public/ /var/www/html/public/

# storage
RUN mkdir -p ./storage/app \
    && mkdir -p ./storage/framework/cache/data \
    && mkdir -p ./storage/framework/sessions \
    && mkdir -p ./storage/framework/views \
    && mkdir -p ./storage/logs \
    && chown -R www-data:www-data ./storage

RUN composer dump-autoload
RUN mv ./.env.prod ./.env 

# alive
COPY ./docker/deployment/php/alive.php /var/www/html/public/

############################################
## PORT
EXPOSE 22
EXPOSE 80

############################################
## Entry Point
COPY docker/deployment/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT bash /usr/local/bin/entrypoint.sh
