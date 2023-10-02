#!/bin/bash

if [ "x$(id -u)" != 'x0' ]; then
  echo "The script can only be run under the root"
  echo "Use command and enter password: sudo sh $0"
  exit 1
fi

ubuntu_version=$(lsb_release -sr)
if [[ "$ubuntu_version" != '22.04' ]]; then
  check_result 1 "Script work only on Ubuntu 22.04"
fi

add-apt-repository ppa:ondrej/php
apt update

software="php8.2 php8.2-bcmath php8.2-xml php8.2-curl"
software+=" php8.2-gd php8.2-mbstring php8.2-mysql php8.2-soap php8.2-tidy php8.2-zip"
software+=" php8.2-apcu php8.2-memcached php8.2-gearman php8.2-xdebug"

apt-get -y install $software

a2dismod php8.0
a2enmod php8.2

apt-get -y purge php8.0* # Remove PHP 8.0

echo "Configuring PHP"
crudini --set /etc/php/8.2/apache2/php.ini PHP allow_url_fopen "1"
crudini --set /etc/php/8.2/cli/php.ini PHP allow_url_fopen "1"

crudini --set /etc/php/8.2/apache2/php.ini PHP apc.entries_hint "524288"
crudini --set /etc/php/8.2/cli/php.ini PHP apc.entries_hint "524288"

crudini --set /etc/php/8.2/apache2/php.ini PHP apc.gc_ttl "600"
crudini --set /etc/php/8.2/cli/php.ini PHP apc.gc_ttl "600"

crudini --set /etc/php/8.2/apache2/php.ini PHP apc.shm_size "512M"
crudini --set /etc/php/8.2/cli/php.ini PHP apc.shm_size "512M"

crudini --set /etc/php/8.2/apache2/php.ini PHP apc.ttl "60"
crudini --set /etc/php/8.2/cli/php.ini PHP apc.ttl "60"

crudini --set /etc/php/8.2/apache2/php.ini PHP display_errors "1"
crudini --set /etc/php/8.2/cli/php.ini PHP display_errors "1"

crudini --set /etc/php/8.2/apache2/php.ini PHP display_startup_errors "0"
crudini --set /etc/php/8.2/cli/php.ini PHP display_startup_errors "0"

crudini --set /etc/php/8.2/apache2/php.ini PHP error_reporting "32767"
crudini --set /etc/php/8.2/cli/php.ini PHP error_reporting "32767"

crudini --set /etc/php/8.2/apache2/php.ini PHP html_errors "0"
crudini --set /etc/php/8.2/cli/php.ini PHP html_errors "0"

crudini --set /etc/php/8.2/apache2/php.ini PHP log_errors "1"
crudini --set /etc/php/8.2/cli/php.ini PHP log_errors "1"

crudini --set /etc/php/8.2/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/8.2/cli/php.ini PHP memory_limit "1024M"

crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.enable "1"
crudini --set /etc/php/8.2/cli/php.ini PHP opcache.enable "1"

crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.max_accelerated_files "10000"
crudini --set /etc/php/8.2/cli/php.ini PHP opcache.max_accelerated_files "10000"

crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.memory_consumption "128"
crudini --set /etc/php/8.2/cli/php.ini PHP opcache.memory_consumption "128"

crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.validate_timestamps "1"
crudini --set /etc/php/8.2/cli/php.ini PHP opcache.validate_timestamps "1"

crudini --set /etc/php/8.2/apache2/php.ini PHP post_max_size "64M"
crudini --set /etc/php/8.2/cli/php.ini PHP post_max_size "64M"

crudini --set /etc/php/8.2/apache2/php.ini PHP upload_max_filesize "64M"
crudini --set /etc/php/8.2/cli/php.ini PHP upload_max_filesize "64M"

crudini --set /etc/php/8.2/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/8.2/cli/php.ini PHP memory_limit "1024M"

crudini --set /etc/php/8.2/apache2/php.ini PHP pcre.jit "0"
crudini --set /etc/php/8.2/cli/php.ini PHP pcre.jit "0"

crudini --set /etc/php/8.2/apache2/php.ini PHP register_argc_argv ""

echo "zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=trigger
xdebug.idekey=PHPSTORM
xdebug.max_nesting_level=-1" > /etc/php/8.2/apache2/conf.d/20-xdebug.ini

service apache2 restart

apt-get -y install php8.2-dev php-pear
pecl uninstall sync
pecl install sync
pecl uninstall yac
echo '' | pecl install yac

touch /etc/php/8.2/mods-available/sync.ini
echo "extension=sync.so" > /etc/php/8.2/mods-available/sync.ini
ln -s /etc/php/8.2/mods-available/sync.ini /etc/php/8.2/apache2/conf.d/sync.ini
ln -s /etc/php/8.2/mods-available/sync.ini /etc/php/8.2/cli/conf.d/sync.ini

touch /etc/php/8.2/mods-available/yac.ini
echo "extension=yac.so" > /etc/php/8.2/mods-available/yac.ini
ln -s /etc/php/8.2/mods-available/yac.ini /etc/php/8.2/apache2/conf.d/yac.ini
ln -s /etc/php/8.2/mods-available/yac.ini /etc/php/8.2/cli/conf.d/yac.ini

sh ~/server.sh