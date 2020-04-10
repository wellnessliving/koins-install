#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if [[ "x$(id -u)" != 'x0' ]]; then
  echo "Script can be run executed only by root"
  echo "Use command and enter password: sudo sh $0"
  exit 1
fi

# Asking for confirmation to proceed
echo "This script remove MySql 5.7 and install MySql 8"
echo "All databases will be deleted!!!"
read -p 'Would you like to continue [y/n]: ' answer
if [[ "$answer" != 'y' ]] && [[ "$answer" != 'Y'  ]]; then
  echo -e 'Goodbye'
  exit 1
fi

read -p 'Write your MySql login: ' MYSQL_USER
if [[ "${MYSQL_USER}" == "root" ]]; then
  echo "Cannot use user: root"
  exit 1
fi

read -p 'Write your MySql password: ' MYSQL_PASS
db_list_all=$(mysql -B -s -u ${MYSQL_USER} --password=${MYSQL_PASS} -e 'show databases' | grep -v information_schema)
if [[ "$?" -gt 0 ]]; then
  echo "Incorrect login or password from MySql"
  exit 1
fi

service mysql start

# Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
crudini --set /etc/mysql/my.cnf mysqld default_time_zone "UTC"

service mysql restart

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger"

# Create new DB user
mysql -uroot -e "create user '${MYSQL_USER}'@'localhost' identified with mysql_native_password by '${MYSQL_PASS}';"

db_list="a_geo studio_trunk_control studio_trunk_main studio_trunk_test_geo studio_trunk_test_main wl_stable_control wl_stable_main wl_stable_test_geo wl_stable_test_main wl_trunk_control wl_trunk_main wl_trunk_shard_business_0 wl_trunk_shard_business_1 wl_trunk_test_geo wl_trunk_test_main wl_trunk_test_shard_business_0 wl_trunk_test_shard_business_1"
for db in ${db_list}; do
  mysql -uroot -e "create database ${db};"
  mysql -uroot -e "grant ${a_privileges} on ${db}.* to '${MYSQL_USER}'@'localhost';"
done

mysql -uroot -e "flush privileges;"

tmp_dir="/tmp/ci-oSRqF0MhDx"
for backup_file in $(ls ${tmp_dir}); do
  echo "Import: ${backup_file}"
  mysql -u ${MYSQL_USER} --password=${MYSQL_PASS} ${backup_file::-4} < ${tmp_dir}/${backup_file}
  echo ""
done
