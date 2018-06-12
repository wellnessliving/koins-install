#!/usr/bin/env bash
# © Vladislav Kobzev, Apr 2018, kp42@ya.ru
# A script for install LAMP on Ubuntu, checkout and setup project.
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
software="mc mcedit apache2 mysql-server php7.1 php7.1-bcmath php7.1-xml php7.1-curl php7.1-gd php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-soap php7.1-tidy php7.1-zip php-apcu php-memcached memcached phpmyadmin crudini libneon27-gnutls dialog putty-tools libserf-1-1"

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
  -w, --workspace           Path to workspace              default: /mnt/c/Workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 --key /path/to/key --passphrase PassPhrase --bot-password BotLogin --bot-login BotPassword --email you@email.com
  Use form for generate install command: http://output.jsbin.com/feguzef"
  exit 1
}

exec 3>&1 1>>${LOG_FILE} 2>&1

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
while getopts "k:p:b:a:e:s:d:c:l:m:g:w:t:fh" Option; do
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

printf "Checking set argument --email: "
if [ ! -n "${email}" ]; then
  check_result 1 "Email not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

unix_workspace=$(echo "${workspace}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_workspace=$(echo "${unix_workspace}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

echo ${unix_workspace}
echo ${win_workspace}

if [ $(echo "${unix_workspace}" | sed 's/^.*\(.\{1\}\)$/\1/') = "/" ]; then
  unix_workspace=${unix_workspace::-1}
fi

if [ $(echo "${win_workspace}" | sed 's/^.*\(.\{1\}\)$/\1/') = "\\" ]; then
  win_workspace=${win_workspace::-1}
fi

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

echo ${key}
unix_key=$(echo "${key}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_key=$(echo "${unix_key}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

if [ $(echo "${unix_key}" | sed 's/^.*\(.\{1\}\)$/\1/') = "/" ]; then
  unix_key=${unix_key::-1}
fi

if [ $(echo "${win_key}" | sed 's/^.*\(.\{1\}\)$/\1/') = "\\" ]; then
  win_key=${win_key::-1}
fi

echo ${unix_key}
echo ${win_key}

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
  mkdir -p ${unix_workspace}/.htprivate/${site}/{options/a,writable/{cache,debug,log,php,sql,tmp,var/selemium,templates/app}} #TODO: Надо проверить создание папки app(writable/templates/app), selemium(writable/var/selemium),a(options/a)
done
echo "[OK]"

echo "Adding php repository..."
add-apt-repository ppa:ondrej/php -y
#TODO: Возможно добавить еще репозиторий phpmyadmin.

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
#Need set mysql root password before install package.
echo "mysql-server mysql-server/root_password password ${db_password}" | sudo debconf-set-selections #TODO: Проверить корректную установку пароля к root пользователю mysql.
echo "mysql-server mysql-server/root_password_again password ${db_password}" | sudo debconf-set-selections

apt-get -y install $software
check_result $? "apt-get install failed"

dpkg -i $(curl -O -s -w '%{filename_effective}' ${libsvn1_17})
dpkg -i $(curl -O -s -w '%{filename_effective}' ${subversion_17})

DIALOG=${DIALOG=dialog}

#curl -s 'link to Studio.API for get user information' -o user.json
#email=$(python -c "import sys, json; print json.load(open('user.json', 'r'))['s_mail']")

#curl -s 'link to Studio.API for get repository information' -o repository.json
#key=$(python -c "import sys, json; print json.load(open('repository.json', 'r'))['key']")
#passphrase=$(python -c "import sys, json; print json.load(open('repository.json', 'r'))['passphrase']")

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"

svn auth
printf "Configuring SVN: "
crudini --set /root/.subversion/config tunnels libs "ssh svn@libs.svn.1024.info -p 35469 -i /root/.ssh/libs.pub"
cp -rf /root/.subversion ${unix_workspace}/Subversion
cp -rf /root/.ssh/libs.key ${unix_workspace}/keys/libs.key
tpm_old_passphrase=$(mktemp -p /tmp)
tmp_new_passphrase=$(mktemp -p /tmp)
printf ${passphrase} > ${tpm_old_passphrase}
puttygen ${unix_workspace}/keys/libs.key -o ${unix_workspace}/keys/libs.ppk --old-passphrase ${tpm_old_passphrase} --new-passphrase ${tmp_new_passphrase}
rm -f ${tpm_old_passphrase}
rm -f ${tmp_new_passphrase}
echo "[OK]"
service ssh restart

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
if [ ! -z "$(grep php7.2-cli ${tmpfile})" ]; then
  apt-get purge php7.2-cli -y
fi
rm -f ${tmpfile}

crudini --set /etc/wsl.conf automount options '"metadata"'

echo "Configuring phpMyAdmin..."
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
#TODO: Разобратся с конфигом /etc/phpmyadmin/config-db.php  Когда он генерируется? Какой пароль устанавливается при установке noninteractive ?
s_pma_password=$(gen_pass)
mysql -e "create user 'phpmyadmin'@'localhost' identified by ${s_pma_password};" #TODO: Установить пароль такой как в config-db.php или в конфиг записать новый.
mysql -e "grant all privileges on *.* to 'phpmyadmin'@'localhost';"
mysql -e "flush privileges"
mysql -u root < /usr/share/doc/phpmyadmin/examples/create_tables.sql

#Add option AcceptFilter to config Apache
echo -e "
AcceptFilter http none" >> /etc/apache2/apache2.conf #TODO: Поискать как сконфигурировать apache без использования echo

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
mysql -e "create user '${db_login}'@'localhost' identified BY '${db_password}';"

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger"
#Creating databases
for project in trunk stable; do
  mysql -e "create database ${project}_wl_main;"
  mysql -e "grant ${a_privileges} on ${project}_wl_main.* to '${db_login}'@'localhost';"
  mysql -e "create database ${project}_wl_geo;"
  mysql -e "grant ${a_privileges} on ${project}_wl_geo.* to '${db_login}'@'localhost';"
  mysql -e "create database ${project}_wl_control;"
  mysql -e "grant ${a_privileges} on ${project}_wl_control.* to '${db_login}'@'localhost';"
  mysql -e "create database ${project}_test_main;"
  mysql -e "grant ${a_privileges} on ${project}_test_main.* to '${db_login}'@'localhost';"
  mysql -e "create database ${project}_test_geo;"
  mysql -e "grant ${a_privileges} on ${project}_test_geo.* to '${db_login}'@'localhost';"
done

mysql -e "flush privileges;"

if [ "$checkout" = 'yes' ]; then
  echo -e "${Purple}#----------------------------------------------------------#
#                    Checkout projects                     #
#----------------------------------------------------------#${NC}"

  #Shared
  svn co svn+libs://libs.svn.1024.info/shared ${unix_workspace}/checkout/shared
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

wget -O ${templates}/windows/install.bat "https://raw.githubusercontent.com/Kasp42/koins-install/trunk/templates/windows/install.bat" #TODO: Delete when merged

sed -e "
s;{host_trunk};${host_trunk};g
s;{host_stable};${host_stable};g
" ${templates}/windows/install.bat > "${unix_workspace}/install.bat"

# Creating link
echo -e "Open the workspace folder: '${Yellow}${win_workspace}${NC}' and run file '${Yellow}install.bat${NC}' as admin."
echo -e "Wait for run file..."
while [ ! -L "${unix_workspace}/wl.stable/project" ];
do
  sleep 2
done
crudini --set ${unix_workspace}/Subversion/config tunnels libs "plink.exe -P 35469 -l svn -i ${win_workspace}\\keys\\libs.ppk libs.svn.1024.info"

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
  cp ${templates}/options/a/cli.php ${unix_workspace}/.htprivate/${site}/options/a/cli.php
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


echo -e "${Purple}#----------------------------------------------------------#
#                     Update Database                      #
#----------------------------------------------------------#${NC}"
#Update DB
for site in $(ls ${unix_workspace}/.htprivate); do
  options=${unix_workspace}/.htprivate/${site}/options

  #TODO: Добавить счетчик попыток и обнавлять базу до тех пор пока не обновится или кол-во попыток не превысит норму.
  echo "Update main DB for ${site}"
  php ${options}/cli.php db.update #Main
  echo "Update test DB for ${site}"
  php ${options}/a-cli.php db.update a #Test

  writable=${unix_workspace}/.htprivate/${site}/writable
  mkdir -p ${writable}/templates/system
  for template in $(php ${options}/cli.php cms.template.list); do
    mkdir -p ${writable}/templates/${template}
  done;
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

#TODO: Подумать что сюда надо еще добавить
# * Что для запуска сервисом использовать команду sh ~/server.sh с под рута или echo 'Password' | sudo --prompt="" -S sh /root/server.sh
echo -e "${Green}
Installation finished successfully.
Created domains:
* ${host_trunk}
* ${host_stable}

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
    echo -e "* ${project}_wl_main
* ${project}_wl_geo
* ${project}_wl_control
* ${project}_test_main
* ${project}_test_geo
"
done
echo -e "Rules have been added to the Windows hosts.

Project checkout  on the path ${win_workspace}

Key for repository 'libs' saved in ${win_workspace}\\keys\\libs.key
Configs for Subversion created for PHPStorm 2018 in %AppData%/Subversion
For work Subversion in PHPStorm 2018 you need downloads 'Subversion for Windows <=1.7.9' and 'Putty'
Subversion: https://sourceforge.net/projects/win32svn/files/1.7.9/apache22/Setup-Subversion-1.7.9.msi/download

1. VCS -> Browse VCS Repository -> Browse Subversion Repository
2. Add new repository: 'svn+libs://libs.svn.1024.info'
${NC}" #TODO: Перенести эту часть инструкции в статью.

exit 0
