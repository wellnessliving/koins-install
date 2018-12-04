#!/bin/bash
# © Vladislav Kobzev, Apr 2018, kp42@ya.ru
# A script for installing LAMP on Ubuntu, checkout and setup project.
#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
#COLORS
# Reset color
NC='\033[0m'              # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple

export DEBIAN_FRONTEND=noninteractive
export PYTHONIOENCODING=utf8 #Need for decode json
software="mc mcedit apache2 mysql-server php7.2 php7.2-bcmath php7.2-xml php7.2-curl php7.2-gd php7.2-mbstring php7.2-mysql php7.2-soap php7.2-tidy php7.2-zip php-apcu php-memcached memcached phpmyadmin crudini libneon27-gnutls dialog putty-tools libserf-1-1 jq"

now="$(date +'%d_%m_%Y_%H_%M')"
LOG_FILE="/root/install_${now}.log"

subversion_17="http://launchpadlibrarian.net/161750374/subversion_1.7.14-1ubuntu2_amd64.deb" #Subversion 1.7 because SVN 1.8 not supported symlinks
libsvn1_17="http://launchpadlibrarian.net/161750375/libsvn1_1.7.14-1ubuntu2_amd64.deb" #Dependence for Subversion 1.7

# Defining return code check function
check_result(){
  if [ "$1" -ne 0 ]; then
    echo -e "${Red} Error: $2 ${NC}"
    exit "$1"
  fi
}

# Defining function to set default value
set_default_value() {
  eval variable=\$$1
  if [ -z "$variable" ]; then
    eval $1=$2
  fi
}

# Defining password-gen function
gen_pass() {
  MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  LENGTH=16
  while [ ${n:=1} -le ${LENGTH} ]; do
    PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    let n+=1
  done
  echo "$PASS"
}

checkout_dialog()
{
  local title=$1
  local source=$2
  local destination=$3
  ${DIALOG}  --keep-tite --backtitle "Subversion checkouting" --title "${title}" --gauge "Getting total file count... It will take some time." 7 120 < <(
    n=$(svn info -R ${source} | grep "URL: " | uniq | wc -l)
    i=1
    while read line filename
      do
      COUNT=$(( 100*(++i)/n))
      if [[ ${filename} = *"out revision"* ]]; then
        COUNT=100
      fi
      echo "XXX"
      echo "$COUNT"
      echo "filename: $filename"
      echo "XXX"

    done < <(svn co ${source} ${destination})
  )
}

# Defining help function
help() {
  echo -e "Usage: $0 [OPTIONS]
  -k, --key                 Path to key for SVN            required
  -p, --passphrase          Passphrase for key             required
  -b, --bot-login           Bot login                      required
  -a, --bot-password        Bot password                   required
  -e, --email               Email                          required
  -d, --db-login            Login for DB                   default: koins
  -c, --db-password         Password for DB                default: lkchpy91
  -l, --prg-login           Login for PRG                  default: admin
  -m, --prg-password        Password for PRG               default: 1
  -g, --checkout            Checkout projects     [yes|no] default: yes
  -x, --xdebug              Install xDebug        [yes|no] default: no
  -w, --workspace           Path to workspace              default: /mnt/c/Workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 --key /path/to/key --passphrase PassPhrase --bot-password BotLogin --bot-login BotPassword --email you@email.com
  Use form to generate install command: http://output.jsbin.com/feguzef"
  exit 1
}

#exec 3>&1 1>>${LOG_FILE} 2>&1

if test "$BASH" = ""; then
  check_result 1 "You must use: bash $0"
fi

# Translating argument to --gnu-long-options
for arg; do
  delimiter=""
  case "$arg" in
    --key)              args="${args}-k " ;;
    --passphrase)       args="${args}-p " ;;
    --bot-login)        args="${args}-b " ;;
    --bot-password)     args="${args}-a " ;;
    --email)            args="${args}-e " ;;
    --db-login)         args="${args}-d " ;;
    --db-password)      args="${args}-c " ;;
    --prg-login)        args="${args}-l " ;;
    --prg-password)     args="${args}-m " ;;
    --checkout)         args="${args}-g " ;;
    --xdebug)           args="${args}-x " ;;
    --workspace)        args="${args}-w " ;;
    --trunk)            args="${args}-t " ;;
    --stable)           args="${args}-s " ;;
    --force)            args="${args}-f " ;;
    --help)             args="${args}-h " ;;
    *)                  [[ "${arg:0:1}" == "-" ]] || delimiter="\""
                        args="${args}${delimiter}${arg}${delimiter} ";;
  esac
done
eval set -- "${args}"

# Parsing arguments
while getopts "k:p:b:a:e:s:d:c:l:m:g:x:w:t:fh" Option; do
  case ${Option} in
    k) key=$OPTARG ;;           # Path to key for SVN
    p) passphrase=$OPTARG ;;    # Passphrase for key
    b) bot_login=$OPTARG ;;     # Bot login
    a) bot_password=$OPTARG ;;  # Bot password
    e) email=$OPTARG ;;         # Email
    d) db_login=$OPTARG ;;      # Login for DB
    c) db_password=$OPTARG ;;   # Password for DB
    l) prg_login=$OPTARG ;;     # Login for PRG
    m) prg_password=$OPTARG ;;  # Password for PRG
    g) checkout=$OPTARG ;;      # Checkout projects
    x) xdebug=$OPTARG ;;        # Checkout projects
    w) workspace=$OPTARG ;;     # Path to workspace
    t) host_trunk=$OPTARG ;;    # Hostname for trunk
    s) host_stable=$OPTARG ;;   # Hostname for stable
    f) force='yes' ;;           # Force installation
    h) help ;;                  # Help
    *) help ;;                  # Print help (default)
  esac
done

#Seting default value for arguments
set_default_value 'db_login' 'koins'
set_default_value 'db_password' 'lkchpy91'
set_default_value 'prg_login' 'admin'
set_default_value 'prg_password' '1'
set_default_value 'checkout' 'yes'
set_default_value 'xdebug' 'no'
set_default_value 'workspace' '/mnt/c/Workspace'
set_default_value 'host_trunk' 'wellnessliving.local'
set_default_value 'host_stable' 'stable.wellnessliving.local'

printf "Checking root permissions: "
if [ "x$(id -u)" != 'x0' ]; then
  check_result 1 "Script can be run executed only by root"
fi
echo "[OK]"

if [ "${host_trunk}" == "${host_stable}" ]; then
  check_result 1 "Host for trunk and host for stable should not be equal."
fi

printf "Checking set argument --bot-login: "
if [ ! -n "${bot_login}" ]; then
  check_result 1 "Bot login not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --bot-password: "
if [ ! -n "${bot_password}" ]; then
  check_result 1 "Bot password not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-login: "
if [ ! -n "${db_login}" ]; then
  check_result 1 "DB login not set or empty. Try 'bash $0 --help' for more information."
fi
if [ "${db_login}" == "root" ]; then
  check_result 1 "DB login must not be root. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-password: "
if [ ! -n "${db_password}" ]; then
  check_result 1 "DB password not set or empty. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

unix_workspace=$(echo "${workspace}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_workspace=$(echo "${unix_workspace}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

if [ $(echo "${unix_workspace}" | sed 's/^.*\(.\{1\}\)$/\1/') = "/" ]; then
  unix_workspace=${unix_workspace::-1}
fi

if [ $(echo "${win_workspace}" | sed 's/^.*\(.\{1\}\)$/\1/') = "\\" ]; then
  win_workspace=${win_workspace::-1}
fi
win_workspace_slash=$(echo "${win_workspace}" | sed -e 's|\\|\\\\|g')

printf "Checking path workspace: "
if [ -d "${unix_workspace:0:6}" ]; then #workspace=/mnt/c/Workspace   ${workspace:0:6}=> /mnt/c
  mkdir -p -v ${unix_workspace}
  if [ ! -z "$(ls -A ${unix_workspace})" ]; then
    if [ "$checkout" == "yes" ]; then
      if [ -z "$force" ]; then
        echo -e "${Red} Directory ${win_workspace} not empty. Please cleanup folder ${win_workspace} ${NC} or use argument --force for automatic cleanup"
        exit 1
      fi
      # Asking for confirmation to proceed
      read -p 'Would you like to clean up workspace folder [y/n]: ' answer
      if [ "$answer" != 'n' ] && [ "$answer" != 'n'  ]; then
        echo -e 'Goodbye'
        exit 1
      fi
      echo -e "${Red}Remove workspace folder...${NC}"
      rm -rf ${unix_workspace}
    fi
  fi
else
  check_result 1 "Path ${win_workspace:0:6} not found."
  exit 1
fi
echo "[OK]"

echo "Checking installed packages..."
tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > ${tmpfile}
for pkg in mysql-server apache2 php7.1; do
  if [ ! -z "$(grep ${pkg} ${tmpfile})" ]; then
    conflicts="$pkg $conflicts"
  fi
done
rm -f ${tmpfile}

#Conflict checking
if [ ! -z "$conflicts" ] && [ -z "$force" ]; then
  echo -e "${Yellow} !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!"
  echo
  echo -e "Following packages are already installed:"
  echo -e ${conflicts}
  echo
  echo -e "It is highly recommended to remove them before proceeding."
  echo
  echo -e "!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!${NC}"
  echo
  check_result 1 "System should be installed on clean server."
fi

printf "Install packages:\n* "
echo ${software} | sed -E -e 's/[[:blank:]]+/\n* /g' #Replace space to newline
echo "Checkout projects: ${checkout}"
#echo "Install xDebug: ${xdebug}"
echo "Workspace: ${win_workspace}"
echo "Login for PRG: ${prg_login}"
echo "Password for PRG: ${prg_password}"
echo "Login for DB: ${db_login}"
echo "Password for DB: ${db_password}"
echo "Email: ${email}"
echo "Host for trunk: ${host_trunk}"
echo "Host for stable: ${host_stable}"
echo

# Asking for confirmation to proceed
read -p 'Would you like to continue [y/n]: ' answer
if [ "$answer" != 'y' ] && [ "$answer" != 'Y'  ]; then
  echo -e 'Goodbye'
  exit 1
fi

printf "Creating file structure: "
mkdir -p ${unix_workspace}/{checkout,keys,.htprivate/{${host_trunk},${host_stable}},wl.trunk,wl.stable,public_html/{a/drive,static}}

for site in $(ls ${unix_workspace}/.htprivate); do
  mkdir -p ${unix_workspace}/.htprivate/${site}/{options,writable/{cache,debug,log,php,sql,tmp,var/selemium}}
done
echo "[OK]"

echo "Adding php repository..."
add-apt-repository ppa:ondrej/php -y

echo -e "${Purple}#----------------------------------------------------------#
#                  Update system packages                 #
#----------------------------------------------------------#${NC}"
apt-get update

echo -e "${Purple}#----------------------------------------------------------#
#                      Upgrade system                      #
#----------------------------------------------------------#${NC}"
apt-get -y upgrade
check_result $? 'apt-get upgrade failed'

echo -e "${Purple}#----------------------------------------------------------#
#                     Install packages                     #
#----------------------------------------------------------#${NC}"
apt-get -y install $software
check_result $? "apt-get install failed"

#Install xdebug
if [ "$xdebug" == "yes" ]; then
  apt-get -y install php-xdebug openssh-server
fi

dpkg -i $(curl -O -s -w '%{filename_effective}' ${libsvn1_17})
dpkg -i $(curl -O -s -w '%{filename_effective}' ${subversion_17})

DIALOG=${DIALOG=dialog}

tmp_repository_file=$(mktemp -p /tmp)
curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Key.json' -X POST --data "s_login=${bot_login}&s_bot_password=${bot_password}&s_repository=libs" -o ${tmp_repository_file}

status=`jq -M -r '.status' ${tmp_repository_file}`

if [ "$status" != 'ok' ]; then
  message=`jq -M -r '.message' ${tmp_repository_file}`
  echo "Error getting repository key: ${message}"
  echo "Status: ${status}"
  echo ${tmp_repository_file}
  exit 1
fi

private_key=`jq -M '.s_private' ${tmp_repository_file}`
passphrase=`jq -M '.s_password' ${tmp_repository_file}`

tmp_repository_key=$(mktemp -p /tmp)
tmp_repository_passphrase=$(mktemp -p /tmp)

echo ${private_key} > $tmp_repository_key
sed -i 's/\\n/\n/g' $tmp_repository_key
sed -i 's/"//g' $tmp_repository_key

echo ${passphrase} > $tmp_repository_passphrase
sed -i 's/"//g' $tmp_repository_passphrase

cp ${tmp_repository_key} ${unix_workspace}/keys/libs.key
key=${unix_workspace}/keys/libs.key
passphrase=$(cat ${tmp_repository_passphrase})

rm -f ${tmp_repository_key}
rm -f ${tmp_repository_passphrase}
rm -f ${tmp_repository_file}

unix_key=$(echo "${key}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_key=$(echo "${unix_key}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

if [ $(echo "${unix_key}" | sed 's/^.*\(.\{1\}\)$/\1/') = "/" ]; then
  unix_key=${unix_key::-1}
fi

if [ $(echo "${win_key}" | sed 's/^.*\(.\{1\}\)$/\1/') = "\\" ]; then
  win_key=${win_key::-1}
fi

printf "Checking set argument --key: "
if [ -n "${unix_key}" ]; then
  if [ ! -f ${unix_key} ]; then
    check_result 1 "No such key file"
  fi
  echo "[OK]"
  printf "Checking set argument --passphrase: "
  if [ -n "${passphrase}" ]; then
    echo "[OK]"
    echo "Decrypting key..."
    mkdir -p /root/.ssh
    cp ${unix_key} /root/.ssh/libs.key
    chmod 600 /root/.ssh/libs.key
    openssl rsa -in /root/.ssh/libs.key -out /root/.ssh/libs.pub -passin pass:${passphrase}
    check_result $? 'Decrypt key error'
    chmod 600 /root/.ssh/libs.pub
  else
    check_result 1 "Passphrase for key not set. Try 'bash $0 --help' for more information."
  fi
else
  check_result 1 "Key not set."
fi

tmp_user_file=$(mktemp -p /tmp)
curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Detail/Detail.json' -X POST --data "s_login=${bot_login}&s_bot_password=${bot_password}" -o ${tmp_user_file}

status=`jq -M -r '.status' ${tmp_user_file}`

if [ "$status" != 'ok' ]; then
  message=`jq -M -r '.message' ${tmp_user_file}`
  echo "Error getting repository key: ${message}"
  echo "Status: ${status}"
  echo ${tmp_user_file}
  exit 1
fi

email=`jq -M -r '.text_mail' ${tmp_user_file}`
rm -f ${tmp_user_file}

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"

#Start all service
service apache2 start
service memcached start

#Configure xdebug
if [ "$xdebug" == "yes" ]; then
  apt-get -y install php-xdebug openssh-server
  dpkg-reconfigure openssh-server

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup # Create backup config file

  user_name=$(echo $(ls /home/)|tr -d '\n')
  sed -i '/^PermitRootLogin/s/^#//g' /etc/ssh/sshd_config # Uncomment line `PermitRootLogin`
  sed -i -e "s;^PermitRootLogin .*$;PermitRootLogin no\nAllowUsers ${user_name};g" /etc/ssh/sshd_config # Set `PermitRootLogin no` and add `AllowUsers`

  sed -i '/^PasswordAuthentication/s/^#//g' /etc/ssh/sshd_config # Uncomment line `PasswordAuthentication`
  sed -i -e "s;^PasswordAuthentication .*$;PasswordAuthentication yes;g" /etc/ssh/sshd_config # Set `PasswordAuthentication yes`

  sed -i '/^UsePrivilegeSeparation/s/^#//g' /etc/ssh/sshd_config # Uncomment line `UsePrivilegeSeparation`
  sed -i -e "s;^UsePrivilegeSeparation .*$;UsePrivilegeSeparation no;g" /etc/ssh/sshd_config # Set `UsePrivilegeSeparation no`
  service ssh --full-restart

  echo "zend_extension=xdebug.so
xdebug.default_enable=0
xdebug.remote_enable=1
xdebug.remote_host=127.0.0.1
xdebug.remote_port=9001
xdebug.idekey=PHPSTORM
xdebug.max_nesting_level=1000" > /etc/php/7.2/apache2/conf.d/20-xdebug.ini

  service apache2 restart
fi

#Configuring svn on WSL
svn info
printf "Configuring SVN: "
crudini --set /root/.subversion/config tunnels libs "ssh svn@libs.svn.1024.info -p 35469 -i /root/.ssh/libs.pub"

#Configure svn on Windows
cp -rf /root/.subversion ${unix_workspace}/Subversion
cp -rf /root/.ssh/libs.key ${unix_workspace}/keys/libs.key
tpm_old_passphrase=$(mktemp -p /tmp)
tmp_new_passphrase=$(mktemp -p /tmp)
printf ${passphrase} > ${tpm_old_passphrase}
puttygen ${unix_workspace}/keys/libs.key -o ${unix_workspace}/keys/libs.ppk --old-passphrase ${tpm_old_passphrase} --new-passphrase ${tmp_new_passphrase}
rm -f ${tpm_old_passphrase}
rm -f ${tmp_new_passphrase}
crudini --set ${unix_workspace}/Subversion/config tunnels libs "plink.exe -P 35469 -l svn -i ${win_workspace_slash}\\\\keys\\\\libs.ppk libs.svn.1024.info"
echo "[OK]"
service ssh restart

crudini --set /etc/my.cnf client port "35072"
crudini --set /etc/my.cnf mysqld port "35072"
crudini --set /etc/my.cnf mysqld max_connections "100"
service mysql start

#set password for mysql user root
mysqladmin -u root password ${db_password}

#Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p${db_password} mysql

echo "Checkouting templates files for configuring system"
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/checkout/reservationspot.com/install

#path to templates
templates=${unix_workspace}/checkout/reservationspot.com/install/templates

if [ ! -d "$templates" ]; then
  svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/checkout/reservationspot.com/install
  if [ ! -d "$templates" ]; then
    check_result 1 "Error while checkouting templates"
  fi
fi

tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > ${tmpfile}
if [ ! -z "$(grep php7.3-cli ${tmpfile})" ]; then
  apt-get purge php7.3-cli -y
fi

rm -f ${tmpfile}

crudini --set /etc/wsl.conf automount options '"metadata"'

echo "Configuring PHP..."
crudini --set /etc/php/7.2/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/7.2/cli/php.ini PHP memory_limit "1024M"

echo "Configuring phpMyAdmin..."
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
s_pma_password=$(gen_pass)
mysql -uroot -p${db_password} -e "create user 'phpmyadmin'@'localhost' identified by '${s_pma_password}';"
mysql -uroot -p${db_password} -e "grant all privileges on *.* to 'phpmyadmin'@'localhost';"
mysql -uroot -p${db_password} -e "flush privileges"
mysql -uroot -p${db_password} < /usr/share/doc/phpmyadmin/examples/create_tables.sql

sed -e "s;%s_pma_password%;${s_pma_password};g" "${templates}/phpmyadmin/config-db.php" > /etc/phpmyadmin/config-db.php

#Add option AcceptFilter to config Apache and restart apache2
echo -e "
AcceptFilter http none" >> /etc/apache2/apache2.conf
service apache2 restart

#Create script to run services
cp ${templates}/sh/server.sh /root/server.sh

#Create script to dump DB
sed -e "s;%workspace%;${unix_workspace};g" ${templates}/sh/dump.sh > /root/dump.sh
crudini --set ~/.my.conf mysqldump user root
crudini --set ~/.my.conf mysqldump password "${db_password}"

# a2enmod & a2enconf
a2enmod rewrite
a2enconf phpmyadmin

#Setting config apache for site
PATH_APACHE="/etc/apache2/sites-available"
document_root=${unix_workspace}/public_html

sed -e "s;%server_alias%;${host_trunk};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host_trunk}.conf"
a2ensite "${host_trunk}.conf"

sed -e "s;%server_alias%;${host_stable};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host_stable}.conf"
a2ensite "${host_stable}.conf"

#Create new DB user
mysql -uroot -p${db_password} -e "create user '${db_login}'@'localhost' identified BY '${db_password}';"

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger"
#Creating databases
for project in trunk stable; do
  mysql -uroot -p${db_password} -e "create database ${project}_wl_main;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_wl_main.* to '${db_login}'@'localhost';"
  mysql -uroot -p${db_password} -e "create database ${project}_wl_geo;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_wl_geo.* to '${db_login}'@'localhost';"
  mysql -uroot -p${db_password} -e "create database ${project}_wl_control;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_wl_control.* to '${db_login}'@'localhost';"
  mysql -uroot -p${db_password} -e "create database ${project}_test_main;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_test_main.* to '${db_login}'@'localhost';"
  mysql -uroot -p${db_password} -e "create database ${project}_test_geo;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_test_geo.* to '${db_login}'@'localhost';"
done
mysql -uroot -p${db_password} -e "flush privileges;"

if [ "$checkout" = 'yes' ]; then
  echo -e "${Purple}#----------------------------------------------------------#
#                    Checkout projects                     #
#----------------------------------------------------------#${NC}"

  #Shared
  checkout_dialog "shared" "svn+libs://libs.svn.1024.info/shared" "${unix_workspace}/checkout/shared"

  #Trunk
  checkout_dialog "[trunk]core" "svn+libs://libs.svn.1024.info/core/trunk" "${unix_workspace}/checkout/core/trunk" #Core
  checkout_dialog "[trunk]namespace.Core" "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${unix_workspace}/checkout/namespace/Core/trunk" #namespace.Core
  checkout_dialog "[trunk]namespace.Social" "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "${unix_workspace}/checkout/namespace/Social/trunk" #namespace.Social
  checkout_dialog "[trunk]namespace.Wl" "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "${unix_workspace}/checkout/namespace/Wl/trunk" #namespace.Wl
  checkout_dialog "[trunk]project" "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "${unix_workspace}/checkout/reservationspot.com/trunk" #project

  #Stable
  checkout_dialog "[stable]core" "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "${unix_workspace}/checkout/core/servers/stable.wellnessliving.com" #Core
  checkout_dialog "[stable]namespace.Core" "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "${unix_workspace}/checkout/namespace/Core/servers/wl-stable" #namespace.Core
  checkout_dialog "[stable]namespace.Social" "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "${unix_workspace}/checkout/namespace/Social/servers/wl-stable" #namespace.Social
  checkout_dialog "[stable]namespace.Wl" "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "${unix_workspace}/checkout/namespace/Wl/servers/stable" #namespace.Wl
  checkout_dialog "[stable]project" "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "${unix_workspace}/checkout/reservationspot.com/servers/stable" #project
fi

sed -e "
s;{host_trunk};${host_trunk};g
s;{host_stable};${host_stable};g
s;{workspace};${win_workspace_slash};g
" ${templates}/windows/install.bat > "${unix_workspace}/install.bat"

# Creating link
echo -e "Open the workspace folder: '${Yellow}${win_workspace}${NC}' and run file '${Yellow}install.bat${NC}' as admin."
echo -e "Wait for run file..."
while [ ! -f "${unix_workspace}/install.bat.done" ];
do
  sleep 2
done
rm -f ${unix_workspace}/install.bat.done

echo -e "${Purple}#----------------------------------------------------------#
#                  Setting default files                   #
#----------------------------------------------------------#${NC}"

path_htprivate="${unix_workspace}/.htprivate/"

#public_html/index.php
sed -e "
s;%path_htprivate%;${path_htprivate};g
s;%host_trunk%;${host_trunk};g
s;%host_stable%;${host_stable};g
" ${templates}/public_html/index.php > "${unix_workspace}/public_html/index.php"

#public_html/.htaccess
sed -e "
s;%workspace%;${unix_workspace};g
s;%host_trunk%;${host_trunk};g
" ${templates}/public_html/.htaccess > "${unix_workspace}/public_html/.htaccess"

#public_html/favicon.ico
cp ${templates}/public_html/favicon.ico "${unix_workspace}/public_html/favicon.ico"

#Options
for site in $(ls ${unix_workspace}/.htprivate); do
  cp ${templates}/options/options.php ${unix_workspace}/.htprivate/${site}/options/options.php
  cp ${templates}/options/inc.php ${unix_workspace}/.htprivate/${site}/options/inc.php
  cp ${templates}/options/cli.php ${unix_workspace}/.htprivate/${site}/options/cli.php
done

for site in $(ls ${unix_workspace}/.htprivate); do
  [ ${site} == ${host_trunk} ] && project="trunk" || project="stable"
  [ ${project} = "trunk" ] && ADDR_URL_SERVER=${host_trunk} || ADDR_URL_SERVER=${host_stable}

  ADDR_PATH_TOP="${unix_workspace}/.htprivate/${ADDR_URL_SERVER}/"
  ADDR_PATH_WORKSPACE="${unix_workspace}/wl.${project}/"
  A_TEST_XML_XSD="${unix_workspace}/shared/xsd/"
  ADDR_SECRET=$(gen_pass)
  PATH_PUBLIC="${unix_workspace}/public_html/"
  path_config=${ADDR_PATH_WORKSPACE}/project/.config
  mkdir -p -v ${path_config}

  #options/addr.php
  sed -e "
  s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g
  s;%ADDR_PATH_WORKSPACE%;${ADDR_PATH_WORKSPACE};g
  s;%A_TEST_XML_XSD%;${A_TEST_XML_XSD};g
  s;%ADDR_SECRET%;${ADDR_SECRET};g
  s;%email%;${email};g
  s;%bot_login%;${bot_login};g
  s;%bot_password%;${bot_password};g
  s;%prg_login%;${prg_login};g
  s;%prg_password%;${prg_password};g
  s;%ADDR_URL_SERVER%;${ADDR_URL_SERVER};g
  s;%PATH_PUBLIC%;${PATH_PUBLIC};g
  " ${templates}/options/addr.php > "${unix_workspace}/.htprivate/${ADDR_URL_SERVER}/options/addr.php"

  #options/db.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project};g
  " ${templates}/options/db.php > "${unix_workspace}/.htprivate/${ADDR_URL_SERVER}/options/db.php"

  #.config/a.test.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project};g
  s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g
  " ${templates}/.config/a.test.php > "${path_config}/a.test.php"

  #.config/amazon.php
  cp ${templates}/.config/amazon.php "${path_config}/amazon.php"
done
cp -a ${templates}/windows/selenium/ ${unix_workspace}

echo -e "${Purple}#----------------------------------------------------------#
#                     Update Database                      #
#----------------------------------------------------------#${NC}"
max_attempt=10
i_attempt=0
#Update DB
for site in $(ls ${unix_workspace}/.htprivate); do
  options=${unix_workspace}/.htprivate/${site}/options

  echo "Update main DB for ${site}"
  while [ ${i_attempt} -lt ${max_attempt} ];
  do
    php ${options}/cli.php db.update #Main
    if [ "$?" -eq 0 ]; then
      break
    fi
    i_attempt=$((i_attempt+1))
  done

  i_attempt=0
  echo "Update test DB for ${site}"
  while [ ${i_attempt} -lt ${max_attempt} ];
  do
    php ${options}/cli.php db.update a #Test
    if [ "$?" -eq 0 ]; then
      break
    fi
    i_attempt=$((i_attempt+1))
  done

  echo "Update messages for ${site}"
  php ${options}/cli.php cms.message.update
done

#Add service to start system
#Maybe not work on WSL
update-rc.d apache2 defaults
update-rc.d mysql defaults
update-rc.d memcached defaults

#Restarl all service
service apache2 restart
service mysql restart
service memcached restart

echo -e "${Green}
Installation finished successfully.

Created domains(rules have been added to the Windows hosts):

    ${host_trunk}
    ${host_stable}

Programmer's page(PRG):

    http://${host_trunk}/prg
    http://${host_stable}/prg
    username: ${prg_login}
    password: ${prg_password}

PHPMyAdmin:

    http://localhost/phpmyadmin
    username: ${db_login}
    password: ${db_password}

MySQL create databases:"

for project in trunk stable; do
    echo -e "    ${project}_wl_main
    ${project}_wl_geo
    ${project}_wl_control
    ${project}_test_main
    ${project}_test_geo
"
done

echo -e "Created script:

    server.sh - For start or restart all service. Use: sh /root/server.sh
    dump.sh - For dump database. Use: sh /root/dump.sh

Project checkout on the path: ${win_workspace}
Key for repository 'libs' saved in ${win_workspace}\\keys\\libs.key${NC}"

exit 0
