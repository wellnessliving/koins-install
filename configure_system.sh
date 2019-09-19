#!/bin/bash

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
crudini --set /etc/mysql/my.cnf mysqld sql_mode ""
crudini --set /etc/mysql/my.cnf mysqld character_set_server "binary"
crudini --set /etc/mysql/my.cnf mysqld log_bin_trust_function_creators "ON"
crudini --set /etc/mysql/my.cnf mysqld max_allowed_packet "104857600"

service mysql restart
service apache2 restart
