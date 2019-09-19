#!/bin/bash

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

# Configuring mysql
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.tmp
sed -i 's/skip\-external\-locking/skip-external-locking=/g' /etc/mysql/mysql.conf.d/mysqld.cnf
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf sql_mode ""
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf character_set_server "binary"
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf log_bin_trust_function_creators "ON"
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf max_allowed_packet "104857600"

# Configuring PHP
crudini --set /etc/php/7.2/apache/php.ini allow_url_fopen "1"
crudini --set /etc/php/7.2/cli/php.ini allow_url_fopen "1"

crudini --set /etc/php/7.2/apache/php.ini apc.entries_hint "524288"
crudini --set /etc/php/7.2/cli/php.ini apc.entries_hint "524288"

crudini --set /etc/php/7.2/apache/php.ini apc.gc_ttl "600"
crudini --set /etc/php/7.2/cli/php.ini apc.gc_ttl "600"

crudini --set /etc/php/7.2/apache/php.ini apc.mmap_file_mask "0"
crudini --set /etc/php/7.2/cli/php.ini apc.mmap_file_mask "0"

crudini --set /etc/php/7.2/apache/php.ini apc.shm_size "512M"
crudini --set /etc/php/7.2/cli/php.ini apc.shm_size "512M"

crudini --set /etc/php/7.2/apache/php.ini apc.ttl "60"
crudini --set /etc/php/7.2/cli/php.ini apc.ttl "60"

crudini --set /etc/php/7.2/apache/php.ini display_errors "1"
crudini --set /etc/php/7.2/cli/php.ini display_errors "1"

crudini --set /etc/php/7.2/apache/php.ini display_startup_errors "0"
crudini --set /etc/php/7.2/cli/php.ini display_startup_errors "0"

crudini --set /etc/php/7.2/apache/php.ini error_reporting "32767"
crudini --set /etc/php/7.2/cli/php.ini error_reporting "32767"

crudini --set /etc/php/7.2/apache/php.ini html_errors "0"
crudini --set /etc/php/7.2/cli/php.ini html_errors "0"

crudini --set /etc/php/7.2/apache/php.ini log_errors "1"
crudini --set /etc/php/7.2/cli/php.ini log_errors "1"

crudini --set /etc/php/7.2/apache/php.ini memory_limit "1024M"
crudini --set /etc/php/7.2/cli/php.ini memory_limit "1024M"

crudini --set /etc/php/7.2/apache/php.ini opcache.enable "1"
crudini --set /etc/php/7.2/cli/php.ini opcache.enable "1"

crudini --set /etc/php/7.2/apache/php.ini opcache.max_accelerated_files "10000"
crudini --set /etc/php/7.2/cli/php.ini opcache.max_accelerated_files "10000"

crudini --set /etc/php/7.2/apache/php.ini opcache.memory_consumption "128"
crudini --set /etc/php/7.2/cli/php.ini opcache.memory_consumption "128"

crudini --set /etc/php/7.2/apache/php.ini opcache.validate_timestamps "1"
crudini --set /etc/php/7.2/cli/php.ini opcache.validate_timestamps "1"

crudini --set /etc/php/7.2/apache/php.ini post_max_size "64M"
crudini --set /etc/php/7.2/cli/php.ini post_max_size "64M"

crudini --set /etc/php/7.2/apache/php.ini upload_max_filesize "64M"
crudini --set /etc/php/7.2/cli/php.ini upload_max_filesize "64M"


service mysql restart
setvice apache2 restart
