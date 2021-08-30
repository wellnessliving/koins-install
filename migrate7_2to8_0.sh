#!/bin/bash

if [ "x$(id -u)" != 'x0' ]; then
  echo "Script can be run executed only by root"
  echo "Use command and enter password: sudo sh $0"
  exit 1
fi

add-apt-repository ppa:ondrej/php
apt update

software="php8.0 php8.0-bcmath php8.0-xml php8.0-curl"
software+=" php8.0-gd php8.0-mbstring php8.0-mysql php8.0-soap php8.0-tidy php8.0-zip"
software+=" php8.0-apcu php8.0-memcached php8.0-dev php8.0-gearman php8.0-xdebug"

apt-get -y install $software

tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > ${tmpfile}
if [ ! -z "$(grep php7.3-cli ${tmpfile})" ]; then
  apt-get -y purge php7.3-cli
fi
rm -f ${tmpfile}

a2dismod php7.2
a2enmod php8.0

apt-get -y purge php7.2* # Remove PHP 7.2

pecl install sync
pecl install inotify

echo "Configuring PHP"
crudini --set /etc/php/8.0/apache2/php.ini PHP allow_url_fopen "1"
crudini --set /etc/php/8.0/cli/php.ini PHP allow_url_fopen "1"

crudini --set /etc/php/8.0/apache2/php.ini PHP apc.entries_hint "524288"
crudini --set /etc/php/8.0/cli/php.ini PHP apc.entries_hint "524288"

crudini --set /etc/php/8.0/apache2/php.ini PHP apc.gc_ttl "600"
crudini --set /etc/php/8.0/cli/php.ini PHP apc.gc_ttl "600"

crudini --set /etc/php/8.0/apache2/php.ini PHP apc.shm_size "512M"
crudini --set /etc/php/8.0/cli/php.ini PHP apc.shm_size "512M"

crudini --set /etc/php/8.0/apache2/php.ini PHP apc.ttl "60"
crudini --set /etc/php/8.0/cli/php.ini PHP apc.ttl "60"

crudini --set /etc/php/8.0/apache2/php.ini PHP display_errors "1"
crudini --set /etc/php/8.0/cli/php.ini PHP display_errors "1"

crudini --set /etc/php/8.0/apache2/php.ini PHP display_startup_errors "0"
crudini --set /etc/php/8.0/cli/php.ini PHP display_startup_errors "0"

crudini --set /etc/php/8.0/apache2/php.ini PHP error_reporting "32767"
crudini --set /etc/php/8.0/cli/php.ini PHP error_reporting "32767"

crudini --set /etc/php/8.0/apache2/php.ini PHP html_errors "0"
crudini --set /etc/php/8.0/cli/php.ini PHP html_errors "0"

crudini --set /etc/php/8.0/apache2/php.ini PHP log_errors "1"
crudini --set /etc/php/8.0/cli/php.ini PHP log_errors "1"

crudini --set /etc/php/8.0/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/8.0/cli/php.ini PHP memory_limit "1024M"

crudini --set /etc/php/8.0/apache2/php.ini PHP opcache.enable "1"
crudini --set /etc/php/8.0/cli/php.ini PHP opcache.enable "1"

crudini --set /etc/php/8.0/apache2/php.ini PHP opcache.max_accelerated_files "10000"
crudini --set /etc/php/8.0/cli/php.ini PHP opcache.max_accelerated_files "10000"

crudini --set /etc/php/8.0/apache2/php.ini PHP opcache.memory_consumption "128"
crudini --set /etc/php/8.0/cli/php.ini PHP opcache.memory_consumption "128"

crudini --set /etc/php/8.0/apache2/php.ini PHP opcache.validate_timestamps "1"
crudini --set /etc/php/8.0/cli/php.ini PHP opcache.validate_timestamps "1"

crudini --set /etc/php/8.0/apache2/php.ini PHP post_max_size "64M"
crudini --set /etc/php/8.0/cli/php.ini PHP post_max_size "64M"

crudini --set /etc/php/8.0/apache2/php.ini PHP upload_max_filesize "64M"
crudini --set /etc/php/8.0/cli/php.ini PHP upload_max_filesize "64M"

crudini --set /etc/php/8.0/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/8.0/cli/php.ini PHP memory_limit "1024M"

touch /etc/php/8.0/mods-available/sync.ini
echo "extension=sync.so" > /etc/php/8.0/mods-available/sync.ini
ln -s /etc/php/8.0/mods-available/sync.ini /etc/php/8.0/apache2/conf.d/sync.ini
ln -s /etc/php/8.0/mods-available/sync.ini /etc/php/8.0/cli/conf.d/sync.ini

touch /etc/php/8.0/mods-available/inotify.ini
echo "extension=inotify.so" > /etc/php/8.0/mods-available/inotify.ini
ln -s /etc/php/8.0/mods-available/inotify.ini /etc/php/8.0/apache2/conf.d/inotify.ini
ln -s /etc/php/8.0/mods-available/inotify.ini /etc/php/8.0/cli/conf.d/inotify.ini

echo "zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=trigger
xdebug.idekey=PHPSTORM
xdebug.max_nesting_level=-1" > /etc/php/8.0/apache2/conf.d/20-xdebug.ini

sh ~/server.sh