#!/bin/bash

if [ "x$(id -u)" != 'x0' ]; then
  echo "Script can be run executed only by root"
  echo "Use command and enter password: sudo sh $0"
  exit 1
fi

package_list=$(mktemp -p /tmp)

if [ ! -z "$(grep php7.1 ${package_list})" ]; then
  echo "PHP 7.1 is not installed."
  exit 1
fi

if [ ! -z "$(grep php7.2 ${package_list})" ]; then
  echo "PHP 7.2 is already installed."
  exit 1
fi

add-apt-repository ppa:ondrej/php
apt update

software="php7.2 php7.2-bcmath php7.2-xml php7.2-curl php7.2-gd php7.2-mbstring php7.2-mysql php7.2-soap php7.2-tidy php7.2-zip"

apt-get -y install $software

rm -f ${package_list}

tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > ${tmpfile}
if [ ! -z "$(grep php7.3-cli ${tmpfile})" ]; then
  apt-get -y purge php7.3-cli
fi
rm -f ${tmpfile}

a2dismod php7.1
a2enmod php7.2

dpkg --get-selections > ${package_list}
if [ ! -z "$(grep php-xdebug ${package_list})" ]; then
  echo "zend_extension=xdebug.so
xdebug.default_enable=0
xdebug.remote_enable=1
xdebug.remote_host=127.0.0.1
xdebug.remote_port=9001
xdebug.idekey=PHPSTORM
xdebug.max_nesting_level=1000" > /etc/php/7.2/apache2/conf.d/20-xdebug.ini
fi

apt-get -y purge php7.1* # Remove PHP 7.1

service ~/server.sh
