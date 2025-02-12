#!/bin/bash
# © Vladislav Kobzev, Apr 2018, kp42@ya.ru
# A script for installing LAMP on Ubuntu, checkout and setup project.
#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
# COLORS
# Reset color
NC='\033[0m' # Text Reset

# Regular Colors
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green
Yellow='\033[0;33m' # Yellow
Purple='\033[0;35m' # Purple

# Defining return code check function
check_result(){
  if [[ "$1" -ne 0 ]]; then
    echo -e "${Red} Error: $2 ${NC}"
    exit "$1"
  fi
}

# Defining function to set default value
set_default_value() {
  eval variable=\$$1
  if [[ -z "$variable" ]]; then
    eval $1=$2
  fi
}

# Defining password-gen function
gen_pass() {
  MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  LENGTH=16
  while [[ ${n:=1} -le ${LENGTH} ]]; do
    PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    let n+=1
  done
  echo "$PASS"
}

# Defining help function
help_message() {
  echo -e "Usage: $0 [OPTIONS]
  -b, --bot-login           Bot login                      required
  -d, --db-login            Login for DB                   default: koins
  -c, --db-password         Password for DB                default: lkchpy91
  -l, --prg-login           Login for PRG                  default: admin
  -w, --workspace           Path to workspace              default: /mnt/c/Workspace
  -k, --studio              Hostname for studio            default: studio.tr
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 -bot-login BotPassword --bot-password BotLogin
  Use form to generate install command: http://output.jsbin.com/feguzef"
  exit 1
}

if test "$BASH" = ""; then
  check_result 1 "You must use: bash $0"
fi

ubuntu_version=$(lsb_release -sr)
minimal_ubuntu_version='18.04';
result=$(expr $minimal_ubuntu_version \<= "$ubuntu_version")
if [ "$result" -eq 0 ]; then
  check_result 1 "Script work only on Ubuntu 18.04 or higher"
fi

# Translating argument to --gnu-long-options
for arg; do
  delimiter=""
  case "$arg" in
    --bot-login)        args="${args}-b " ;;
    --db-login)         args="${args}-d " ;;
    --db-password)      args="${args}-c " ;;
    --prg-login)        args="${args}-l " ;;
    --workspace)        args="${args}-w " ;;
    --studio)           args="${args}-k " ;;
    --force)            args="${args}-f " ;;
    --help)             args="${args}-h " ;;
    *)                  [[ "${arg:0:1}" == "-" ]] || delimiter="\""
                        args="${args}${delimiter}${arg}${delimiter} ";;
  esac
done
eval set -- "${args}"

# Parsing arguments
while getopts "b:k:d:c:l:w:fh" Option; do
  case ${Option} in
    b) bot_login=$OPTARG ;;        # Bot login
    d) db_login=$OPTARG ;;         # Login for DB
    c) db_password=$OPTARG ;;      # Password for DB
    l) prg_login=$OPTARG ;;        # Login for PRG
    w) workspace=$OPTARG ;;        # Path to workspace
    k) host_studio=$OPTARG ;;      # Hostname for studio
    f) force='yes' ;;              # Force installation
    h) help_message ;;             # Help
    *) help_message ;;             # Print help (default)
  esac
done

# Setting default value for arguments
set_default_value 'db_login' 'koins'
set_default_value 'db_password' 'lkchpy91'
set_default_value 'prg_login' 'admin'
set_default_value 'workspace' '/mnt/c/Workspace'
set_default_value 'host_studio' 'studio.tr'

printf "Checking root permissions: "
if [[ "x$(id -u)" != 'x0' ]]; then
  check_result 1 "The script can only be run under the root"
fi
echo "[OK]"

printf "Checking set argument --bot-login: "
if [[ ! -n "${bot_login}" ]]; then
  check_result 1 "Bot login not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-login: "
if [[ ! -n "${db_login}" ]]; then
  check_result 1 "DB login not set or empty. Try 'bash $0 --help' for more information."
fi
if [[ "${db_login}" == "root" ]]; then
  check_result 1 "DB login must not be root. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-password: "
if [[ ! -n "${db_password}" ]]; then
  check_result 1 "DB password not set or empty. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

unix_workspace=$(echo "${workspace}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_workspace=$(echo "${unix_workspace}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

if [[ $(echo ${unix_workspace: -1}) == "/" ]]; then
  unix_workspace=${unix_workspace::-1}
fi

if [[ $(echo ${win_workspace: -1}) == "\\" ]]; then
  win_workspace=${win_workspace::-1}
fi
win_workspace_slash=$(echo "${win_workspace}" | sed -e 's|\\|\\\\|g')

echo "Workspace: ${win_workspace}"
echo "Login for PRG: ${prg_login}"
echo "Login for DB: ${db_login}"
echo "Password for DB: ${db_password}"
echo "Host for studio: ${host_studio}"
echo

# Asking for confirmation to proceed
read -p 'Would you like to continue [y/n]: ' answer
if [[ "$answer" != 'y' ]] && [[ "$answer" != 'Y'  ]]; then
  echo -e 'Goodbye'
  exit 1
fi

a_site="studio.trunk"

printf "Creating file structure: "

mkdir -p ${unix_workspace}/keys
mkdir -p ${unix_workspace}/less/3.9.0
mkdir -p ${unix_workspace}/less/4.1.3

for project in ${a_site}; do
  mkdir -p ${unix_workspace}/${project}/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
done

echo "[OK]"

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"

status=""
while [ "$status" != "ok" ]; do
  read -p 'Write one time password from studio: ' one_time_password
  if [[ -z "$one_time_password" ]]; then
    continue
  fi

  tmp_user_file=$(mktemp -p /tmp)

  curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Detail/Detail.json' -X POST --data "s_login=${bot_login}&s_user_password=${one_time_password}" -o ${tmp_user_file}

  status=`jq -M -r '.status' ${tmp_user_file}`

  if [[ "$status" != 'ok' ]]; then
    message=`jq -M -r '.message' ${tmp_user_file}`
    echo "Error getting repository key: ${message}"
    echo "Status: ${status}"
    echo ${tmp_user_file}
    echo
    read -p 'Try again?[y/n]: ' answer
    if [[ "$answer" = 'n' ]] || [[ "$answer" = 'N'  ]]; then
      exit 1
    fi
  fi
done

email=`jq -M -r '.text_mail' ${tmp_user_file}`
bot_password=`jq -M -r '.s_bot_password' ${tmp_user_file}`
rm -f ${tmp_user_file}

mkdir -p ${unix_workspace}/install_tmp

echo "Checkouting templates files for configuring system"
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp

install_tmp=${unix_workspace}/install_tmp
# path to templates
templates=${install_tmp}/templates

if [[ ! -d "$templates" ]]; then
  svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp
  if [[ ! -d "$templates" ]]; then
    check_result 1 "Error while checkouting templates"
  fi
fi

# Setting config apache for site
PATH_APACHE="/etc/apache2/sites-available"

for project in ${a_site}; do
  document_root=${unix_workspace}/${project}/public_html

  host=${host_studio}

  sed -e "s;%server_alias%;${host};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host}.conf"
  a2ensite "${host}.conf"
done

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger,create temporary tables,alter routine,create routine,execute"

# Creating databases
for project in ${a_site}; do
  project=$(echo "$project" | sed -r 's/\./_/g')
  a_db_list="main control test_main test_geo test_shard_0 test_shard_1 test_create xa"

  s_prefix=$(echo "$project" | sed -r 's/_[a-z_]+//g')
  if [[ ${s_prefix} == "wl" ]]; then
    a_db_list+=" shard_0 shard_1"
  fi

  for db_name in ${a_db_list}; do
    mysql -uroot -e "create database ${project}_${db_name};"
    mysql -uroot -e "grant ${a_privileges} on ${project}_${db_name}.* to '${db_login}'@'localhost';"
    mysql -uroot -e "grant select on ${project}_${db_name}.* to '${db_login}_read'@'localhost';"
  done
done
mysql -uroot -e "flush privileges;"

echo -e "${Purple}#----------------------------------------------------------#
#                    Checkout projects                     #
#----------------------------------------------------------#${NC}"
# Studio
svn co "svn+libs://libs.svn.1024.info/core/trunk" "${unix_workspace}/studio.trunk/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${unix_workspace}/studio.trunk/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Studio/trunk" "${unix_workspace}/studio.trunk/namespace.Studio" # namespace.Studio
svn co "svn+libs://libs.svn.1024.info/dev.1024.info/trunk" "${unix_workspace}/studio.trunk/project" # project
svn co "svn+libs://libs.svn.1024.info/Thoth/DriveMs/trunk" "${unix_workspace}/studio.trunk/Thoth/DriveMs" # Thoth DriveMs

echo -e "${Purple}#----------------------------------------------------------#
#                  Setting default files                   #
#----------------------------------------------------------#${NC}"

s_geo_host=$(crudini --get ${install_tmp}/config/geo.ini connect host)
s_geo_login=$(crudini --get ${install_tmp}/config/geo.ini connect login)
s_geo_name=$(crudini --get ${install_tmp}/config/geo.ini connect name)
s_geo_password=$(crudini --get ${install_tmp}/config/geo.ini connect password)
for project in ${a_site}; do
  path_htprivate="${unix_workspace}/${project}/.htprivate"

  ALL_MAIN="rs"
  s_addr_template=${templates}/options/addr.wl.php
  s_config_template=${templates}/.config/a.test.wl.php
  s_db_template=${templates}/options/db.wl.php
  s_options_template=${templates}/options/options.wl.php
  if [[ "$project" == "studio.trunk" ]]; then
    host=${host_studio}
    ALL_MAIN="studio"
    s_addr_template=${templates}/options/addr.studio.php
    s_config_template=${templates}/.config/a.test.studio.php
    s_db_template=${templates}/options/db.studio.php
    s_options_template=${templates}/options/options.studio.php
  fi

  # public_html/index.php
  cp ${templates}/public_html/index.php "${unix_workspace}/${project}/public_html/index.php"

  # public_html/.htaccess
  sed -e "
  s;%workspace%;${unix_workspace};g
  s;%project%;${project};g
  " ${templates}/public_html/.htaccess > "${unix_workspace}/${project}/public_html/.htaccess"

  # public_html/favicon.ico
  cp ${templates}/public_html/favicon.ico "${unix_workspace}/${project}/public_html/favicon.ico"

  cp ${s_options_template} ${unix_workspace}/${project}/.htprivate/options/options.php
  cp ${templates}/options/inc.php ${unix_workspace}/${project}/.htprivate/options/inc.php
  cp ${templates}/options/cli.php ${unix_workspace}/${project}/.htprivate/options/cli.php

  ADDR_SECRET=$(gen_pass)
  path_config=${unix_workspace}/${project}/project/.config
  mkdir -p -v ${path_config}

  # options/addr.php
  sed -e "
  s;%ALL_MAIN%;${ALL_MAIN};g
  s;%CLASS_INITIALIZE%;${CLASS_INITIALIZE};g
  s;%CONFIGURATION_NAME%;${CONFIGURATION_NAME};g
  s;%ADDR_SECRET%;${bot_login};g
  s;%email%;${email};g
  s;%bot_login%;${bot_login};g
  s;%bot_password%;${bot_password};g
  s;%prg_login%;${prg_login};g
  s;%ADDR_URL_SERVER%;${host};g
  " ${s_addr_template} > "${path_htprivate}/options/addr.php"

  project_db=$(echo "$project" | sed -r 's/\./_/g')

  # options/db.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project_db};g
  s;%GEO_HOST%;${s_geo_host};g
  s;%GEO_LOGIN%;${s_geo_login};g
  s;%GEO_NAME%;${s_geo_name};g
  s;%GEO_PASSWORD%;${s_geo_password};g
  " ${s_db_template} > "${path_htprivate}/options/db.php"

  #.config/a.test.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project_db};g
  " ${s_config_template} > "${path_config}/a.test.php"
done

chmod 777 -R ${unix_workspace}
chmod -R 777 /dev/shm/

rm -rf ${unix_workspace}/install_tmp

# Restart all service
service apache2 restart
service mysql restart
service memcached restart
service dynamodb start
service gearman-job-server start

echo -e "${Green}
Installation finished successfully.

Programmer's page(PRG):

    PRG username: ${prg_login}

MySql:
    username: ${db_login}
    password: ${db_password}
"

echo -e "Created script:

    server.sh - For start or restart all service. Use: sh /root/server.sh
    dump.sh - For dump database. Use: sh /root/dump.sh

Project checkout on the path: ${win_workspace}
Key for repository 'libs' saved in ${win_workspace}\\keys\\libs.key${NC}"

exit 0