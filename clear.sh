#!/bin/bash

if test "$BASH" = ""; then
  echo "You must use: bash $0"
  exit 1
fi

s_project_dir="$1"

if [[ ! -d "$s_project_dir" ]]; then
  echo "Project dir does not exist: $s_project_dir"
  exit 1
fi

if [[ ! -d "$s_project_dir/.htprivate" ]]; then
  echo "Project dir is not valid."
  exit
fi

service apache2 stop
service memcached stop
service mysql stop

# Clear .htprivate
rm -rfv ${s_project_dir}/.htprivate/writable/cache
rm -rfv ${s_project_dir}/.htprivate/writable/log
rm -rfv ${s_project_dir}/.htprivate/writable/log-queue
rm -rfv ${s_project_dir}/.htprivate/writable/sos
rm -rfv ${s_project_dir}/.htprivate/writable/testSos
rm -rfv ${s_project_dir}/.htprivate/writable/tmp
rm -rfv ${s_project_dir}/.htprivate/writable/var

# Clear public_html
rm -rfv ${s_project_dir}/public_html/static
rm -rfv ${s_project_dir}/public_html/debug
rm -rfv ${s_project_dir}/public_html/prg
rm -rfv ${s_project_dir}/public_html/rs
rm -rfv ${s_project_dir}/public_html/studio
rm -rfv ${s_project_dir}/public_html/im
rm -rfv ${s_project_dir}/public_html/xmlfilter

# Clear /dev/shm/
rm -rfv /dev/shm/

# Recreate directory
mkdir -pv ${s_project_dir}/.htprivate/writable/var/selenium
mkdir -pv ${s_project_dir}/.htprivate/writable/cache
mkdir -pv ${s_project_dir}/.htprivate/writable/tmp
mkdir -pv ${s_project_dir}/.htprivate/writable/log
chmod 777 -R ${s_project_dir}/.htprivate/writable

service apache2 start
service memcached start
service mysql start
