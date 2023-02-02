#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if [[ "x$(id -u)" != 'x0' ]]; then
  echo "The script can only be run under the root"
  echo "Use command and enter password: sudo bash $0"
  exit 1
fi

if test "$BASH" = ""; then
  echo "You must use: bash $0"
  exit 1
fi

# Asking for confirmation to proceed
echo "This script remove old MySql and install MySql 8"
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

backup_dir="/root/backup/$(date +%Y-%m-%d_%H_%M_%S)"
mkdir -p ${backup_dir}
echo ${db_list_all} > "/root/backup/db_list_$(date +%Y-%m-%d_%H_%M_%S)"

db_list=""
# Get the database list, exclude information_schema
for db in ${db_list_all}; do
  db_list+=" ${db}"
  if [[ "${db}" == *"test"* ]] || [[ "${db}" == "a_geo" ]] || [[ "${db}" == "mysql" ]] || [[ "${db}" == "information_schema" ]] || [[ "${db}" == "performance_schema" ]] || [[ "${db}" == "sys" ]] || [[ "${db}" == *"control"* ]]; then
    echo "Ignore database: ${db}"
  else
    echo "Dumping database: ${db}"
    # dump each database in a separate file
    mysqldump -u ${MYSQL_USER} --password=${MYSQL_PASS} --no-tablespaces --ignore-table=${db}.a_log --ignore-table=${db}.core_log_deprecate --ignore-table=${db}.core_log_data --ignore-table=${db}.core_log_state --ignore-table=${db}.core_log_cache --ignore-table=${db}.core_search_provider_index --ignore-table=${db}.core_amazon_search_index --ignore-table=${db}.core_sos_provider_database --skip-triggers "$db" > "$backup_dir/$db.sql"
  fi
done
echo "Dump save to: ${backup_dir}"

# Update packages
apt-get update

apt-get install libaio1 libaio-dev crudini -y

service mysql stop

apt-get purge mysql-server* mysql-client* mysql-common* -y

apt-get autoremove -y
apt-get autoclean -y

rm -rf /etc/mysql
rm -rf /usr/local/mysql
rm -rf /usr/local/sql
rm -rf /etc/init.d/mysql
rm -rf /var/log/mysql/
rm -rf /var/lib/mysql/

# Download MySql 8.0.25 sources
wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.25-linux-glibc2.12-x86_64.tar.xz
if [[ "$?" -gt 0 ]]; then
  echo "Cannot download mysql"
  exit 1
fi

# Extract all files from archive and delete archive.
mkdir -p /usr/local/sql
tar xf mysql-8.0.25-linux-glibc2.12-x86_64.tar.xz -C /usr/local/sql
rm -rf mysql-8.0.25-linux-glibc2.12-x86_64.tar.xz

# Installing MySql
SQL_BIN="mysql-8.0.25-linux-glibc2.12-x86_64"

groupadd -f mysql
useradd -r -g mysql -s /bin/false mysql
cd /usr/local
ln -s /usr/local/sql/${SQL_BIN} /usr/local/mysql
chmod 755 -R /usr/local/sql/${SQL_BIN}
chown mysql:mysql -R /usr/local/sql/${SQL_BIN}
cd mysql
bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql
chown mysql:mysql -R /usr/local/sql/${SQL_BIN}

# Creating mysql service and command
for s_bin in /usr/local/mysql/bin/*; do
  s_file=$(basename ${s_bin})
  if [[ ${s_file} == *"mysql"* ]]; then
    if [[ -f "/usr/bin/${s_file}" ]]; then
      rm -f /usr/bin/${s_file}
    fi
    ln -s ${s_bin} /usr/bin/${s_file}
  fi
done

ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql

# Configuring MySql
mkdir -p /var/log/mysql/
chmod 750 -R /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chown -R mysql:adm /var/log/mysql

mkdir -p /etc/mysql/conf.d
touch /etc/mysql/my.cnf
chmod 444 /etc/mysql/my.cnf

crudini --set /etc/mysql/my.cnf mysqld sql_mode ""
crudini --set /etc/mysql/my.cnf mysqld character_set_server "binary"
crudini --set /etc/mysql/my.cnf mysqld log_bin_trust_function_creators "ON"
crudini --set /etc/mysql/my.cnf mysqld max_allowed_packet "104857600"
crudini --set /etc/mysql/my.cnf mysqld innodb_flush_log_at_timeout "60"
crudini --set /etc/mysql/my.cnf mysqld innodb_flush_log_at_trx_commit "0"
crudini --set /etc/mysql/my.cnf mysqld default_authentication_plugin "mysql_native_password"
crudini --set /etc/mysql/my.cnf mysqld innodb_use_native_aio "off"
crudini --set /etc/mysql/my.cnf mysqld port "3306"
crudini --set /etc/mysql/my.cnf mysqld log_error "/var/log/mysql/mysql.log"

service mysql start

# Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
crudini --set /etc/mysql/my.cnf mysqld default_time_zone "UTC"

service mysql restart

# Create new DB user
mysql -uroot -e "create user '${MYSQL_USER}'@'localhost' identified with mysql_native_password by '${MYSQL_PASS}';"
mysql -uroot -e "create user '${MYSQL_USER}_read'@'localhost' identified with mysql_native_password by '${MYSQL_PASS}';"

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger,create temporary tables,alter routine,create routine,execute"

mysql -uroot -e "create database a_geo;"
mysql -uroot -e "grant ${a_privileges} on a_geo.* to '${MYSQL_USER}'@'localhost';"
mysql -uroot -e "grant session_variables_admin on *.* to '${MYSQL_USER}'@'localhost';"
mysql -uroot -e "grant select on a_geo.* to '${MYSQL_USER}_read'@'localhost';"

for db in ${db_list}; do
  mysql -uroot -e "create database ${db};"
  mysql -uroot -e "grant ${a_privileges} on ${db}.* to '${MYSQL_USER}'@'localhost';"
  mysql -uroot -e "grant select on ${db}.* to '${MYSQL_USER}_read'@'localhost';"
done

mysql -uroot -e "flush privileges;"

for backup_file in $(ls ${backup_dir}); do
  echo "Import: ${backup_file}"
  mysql -u ${MYSQL_USER} --password=${MYSQL_PASS} ${backup_file::-4} < ${backup_dir}/${backup_file}
  echo ""
done
