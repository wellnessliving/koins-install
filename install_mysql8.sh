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

# Update packages
apt update

apt install libaio1 libaio-dev -y

package_list=$(mktemp -p /tmp)
dpkg --get-selections > ${package_list}
if [[ -z "$(grep crudini ${package_list})" ]]; then
  echo "Crudini is not installed."
  exit 1
fi
rm ${package_list}

service mysql stop

apt purge mysql-server* mysql-client* mysql-common* -y

apt autoremove -y
apt autoclean -y

rm -rf /etc/mysql
rm -rf /usr/local/mysql
rm -rf /usr/local/sql

# Download MySql 8.0.16 sources
wget -c https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz
if [[ "$?" -gt 0 ]]; then
  echo "Cannot download mysql"
  exit 1
fi

# Extract all files from archive and delete archive.
mkdir -p /usr/local/sql
tar xf mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz -C /usr/local/sql
rm -rf mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz

# Installing MySql
SQL_BIN="mysql-8.0.16-linux-glibc2.12-x86_64"

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
    ln -s ${s_bin} /usr/bin/${s_file}
  fi
done

ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql

# Configuring MySql
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

service mysql start

# Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
crudini --set /etc/mysql/my.cnf mysqld default_time_zone "UTC"

service mysql restart

