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

export DEBIAN_FRONTEND=noninteractive
export PYTHONIOENCODING=utf8 # Need for decode json

software="mc mcedit putty-tools crudini"
software+=" apache2 php7.2 php7.2-bcmath php7.2-xml php7.2-curl"
software+=" php7.2-gd php7.2-mbstring php7.2-mysql php7.2-soap php7.2-tidy php7.2-zip"
software+=" php-apcu php-memcached memcached libneon27-gnutls libserf-1-1 jq subversion npm nodejs libaio1 libaio-dev"

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
  -a, --bot-password        Bot password                   required
  -d, --db-login            Login for DB                   default: koins
  -c, --db-password         Password for DB                default: lkchpy91
  -l, --prg-login           Login for PRG                  default: admin
  -m, --prg-password        Password for PRG               default: 1
  -g, --checkout            Checkout projects     [yes|no] default: yes
  -x, --xdebug              Install xDebug        [yes|no] default: yes
  -w, --workspace           Path to workspace              default: /mnt/c/Workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -p, --production          Hostname for production
  -k, --studio              Hostname for studio
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 -bot-login BotPassword --bot-password BotLogin
  Use form to generate install command: http://output.jsbin.com/feguzef"
  exit 1
}

if test "$BASH" = ""; then
  check_result 1 "You must use: bash $0"
fi

# Translating argument to --gnu-long-options
for arg; do
  delimiter=""
  case "$arg" in
    --bot-login)        args="${args}-b " ;;
    --bot-password)     args="${args}-a " ;;
    --db-login)         args="${args}-d " ;;
    --db-password)      args="${args}-c " ;;
    --prg-login)        args="${args}-l " ;;
    --prg-password)     args="${args}-m " ;;
    --checkout)         args="${args}-g " ;;
    --xdebug)           args="${args}-x " ;;
    --workspace)        args="${args}-w " ;;
    --trunk)            args="${args}-t " ;;
    --stable)           args="${args}-s " ;;
    --production)       args="${args}-p " ;;
    --studio)           args="${args}-k " ;;
    --force)            args="${args}-f " ;;
    --help)             args="${args}-h " ;;
    *)                  [[ "${arg:0:1}" == "-" ]] || delimiter="\""
                        args="${args}${delimiter}${arg}${delimiter} ";;
  esac
done
eval set -- "${args}"

# Parsing arguments
while getopts "b:a:s:k:p:d:c:l:m:g:x:w:t:fh" Option; do
  case ${Option} in
    b) bot_login=$OPTARG ;;        # Bot login
    a) bot_password=$OPTARG ;;     # Bot password
    d) db_login=$OPTARG ;;         # Login for DB
    c) db_password=$OPTARG ;;      # Password for DB
    l) prg_login=$OPTARG ;;        # Login for PRG
    m) prg_password=$OPTARG ;;     # Password for PRG
    g) checkout=$OPTARG ;;         # Checkout projects
    x) xdebug=$OPTARG ;;           # Checkout projects
    w) workspace=$OPTARG ;;        # Path to workspace
    t) host_trunk=$OPTARG ;;       # Hostname for trunk
    s) host_stable=$OPTARG ;;      # Hostname for stable
    p) host_production=$OPTARG ;;  # Hostname for production
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
set_default_value 'prg_password' '1'
set_default_value 'checkout' 'yes'
set_default_value 'xdebug' 'yes'
set_default_value 'workspace' '/mnt/c/Workspace'
set_default_value 'host_trunk' 'wellnessliving.local'
set_default_value 'host_stable' 'stable.wellnessliving.local'

printf "Checking root permissions: "
if [[ "x$(id -u)" != 'x0' ]]; then
  check_result 1 "Script can be run executed only by root"
fi
echo "[OK]"

if [[ "${host_trunk}" == "${host_stable}" ]] || [[ "${host_trunk}" == "${host_production}" ]] || [[ "${host_trunk}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

if [[ "${host_stable}" == "${host_production}" ]] || [[ "${host_stable}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

if [[ ! -z "$host_production" ]] && [[ ! -z "$host_studio" ]] && [[ "${host_production}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

printf "Checking set argument --bot-login: "
if [[ ! -n "${bot_login}" ]]; then
  check_result 1 "Bot login not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --bot-password: "
if [[ ! -n "${bot_password}" ]]; then
  check_result 1 "Bot password not set. Try 'bash $0 --help' for more information."
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

printf "Checking path workspace: "
if [[ -d "${unix_workspace:0:6}" ]]; then # workspace=/mnt/c/Workspace   ${workspace:0:6}=> /mnt/c
  mkdir -p -v ${unix_workspace}
  if [[ ! -z "$(ls -A ${unix_workspace})" ]]; then
    if [[ "$checkout" == "yes" ]]; then
      if [[ -z "$force" ]]; then
        echo -e "${Red} Directory ${win_workspace} not empty. Please cleanup folder ${win_workspace} ${NC} or use argument --force for automatic cleanup"
        exit 1
      fi
      echo -e "${Red}Force installing${NC}"
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
for pkg in mysql-server apache2 php7.2; do
  if [[ ! -z "$(grep ${pkg} ${tmpfile})" ]]; then
    conflicts="$pkg $conflicts"
  fi
done
rm -f ${tmpfile}

# Conflict checking
if [[ ! -z "$conflicts" ]] && [[ -z "$force" ]]; then
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
echo ${software} | sed -E -e 's/[[:blank:]]+/\n* /g' # Replace space to newline
echo "Install xDebug: ${xdebug}"
echo "Checkout projects: ${checkout}"
echo "Workspace: ${win_workspace}"
echo "Login for PRG: ${prg_login}"
echo "Password for PRG: ${prg_password}"
echo "Login for DB: ${db_login}"
echo "Password for DB: ${db_password}"
echo "Host for trunk: ${host_trunk}"
echo "Host for stable: ${host_stable}"
echo "Host for production: ${host_production}"
echo "Host for studio: ${host_studio}"
echo

# Asking for confirmation to proceed
read -p 'Would you like to continue [y/n]: ' answer
if [[ "$answer" != 'y' ]] && [[ "$answer" != 'Y'  ]]; then
  echo -e 'Goodbye'
  exit 1
fi

a_site=""

# Folders for production
if [[ ! -z "$host_trunk" ]]; then
  a_site+=" wl.trunk"
fi

# Folders for studio
if [[ ! -z "$host_stable" ]]; then
  a_site+=" wl.stable"
fi

# Folders for production
if [[ ! -z "$host_production" ]]; then
  a_site+=" wl.production"
fi

# Folders for studio
if [[ ! -z "$host_studio" ]]; then
  a_site+=" studio.trunk"
fi

if [[ ! -n "${a_site}" ]]; then
  check_result 1 "You must select at least one site."
fi

printf "Creating file structure: "

mkdir -p ${unix_workspace}/keys
mkdir -p ${unix_workspace}/less/3.9.0

for project in ${a_site}; do
  mkdir -p ${unix_workspace}/${project}/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
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
#             Install packages and dependencies            #
#----------------------------------------------------------#${NC}"
apt-get -y install ${software}
check_result $? "apt-get install failed"

# Download MySql 8.0.16 sources
wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.19-linux-glibc2.12-x86_64.tar.xz

# Extract all files from archive and delete archive.
mkdir -p /usr/local/sql
tar xf mysql-8.0.19-linux-glibc2.12-x86_64.tar.xz -C /usr/local/sql
rm -rf mysql-8.0.19-linux-glibc2.12-x86_64.tar.xz

# Installing MySql
SQL_BIN="mysql-8.0.19-linux-glibc2.12-x86_64"

groupadd mysql
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

cd ${unix_workspace}/less/3.9.0 && npm install less@3.9.0

# Remove php 7.3 and php 7.4 if installed.
apt-get purge php7.3-cli php7.4-cli -y

# Install Pecl and Sync extension.
apt -y install php7.2-dev php-pear
pecl install sync

# Install Gearman
apt -y install gearman php-gearman

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"
tmp_repository_file=$(mktemp -p /tmp)
curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Key.json' -X POST --data "s_login=${bot_login}&s_bot_password=${bot_password}&s_repository=libs" -o ${tmp_repository_file}

status=`jq -M -r '.status' ${tmp_repository_file}`

if [[ "$status" != 'ok' ]]; then
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

echo ${private_key} > ${tmp_repository_key}
sed -i 's/\\n/\n/g' ${tmp_repository_key}
sed -i 's/"//g' ${tmp_repository_key}

echo ${passphrase} > ${tmp_repository_passphrase}
sed -i 's/"//g' ${tmp_repository_passphrase}

cp ${tmp_repository_key} ${unix_workspace}/keys/libs.key
key=${unix_workspace}/keys/libs.key
passphrase=$(cat ${tmp_repository_passphrase})

rm -f ${tmp_repository_key}
rm -f ${tmp_repository_passphrase}
rm -f ${tmp_repository_file}

unix_key=$(echo "${key}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')
win_key=$(echo "${unix_key}" | sed -e 's|^/mnt/\([A-Za-z]\)/\(.*\)|\U\1:\E/\2|' -e 's|/|\\|g')

if [[ $(echo ${unix_key: -1}) == "/" ]]; then
  unix_key=${unix_key::-1}
fi

if [[ $(echo ${win_key: -1}) == "\\" ]]; then
  win_key=${win_key::-1}
fi

printf "Checking set argument --key: "
if [[ -n "${unix_key}" ]]; then
  if [[ ! -f ${unix_key} ]]; then
    check_result 1 "No such key file"
  fi
  echo "[OK]"
  printf "Checking set argument --passphrase: "
  if [[ -n "${passphrase}" ]]; then
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

if [[ "$status" != 'ok' ]]; then
  message=`jq -M -r '.message' ${tmp_user_file}`
  echo "Error getting repository key: ${message}"
  echo "Status: ${status}"
  echo ${tmp_user_file}
  exit 1
fi

email=`jq -M -r '.text_mail' ${tmp_user_file}`
rm -f ${tmp_user_file}

# Add option AcceptFilter to config Apache and restart apache2
echo -e "
AcceptFilter http none" >> /etc/apache2/apache2.conf

# Configure xdebug
if [[ "$xdebug" == "yes" ]]; then
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

# Configuring svn on WSL
svn info
printf "Configuring SVN: "
crudini --set /root/.subversion/config tunnels libs "ssh svn@libs.svn.1024.info -p 35469 -i /root/.ssh/libs.pub"

# Configure svn on Windows
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

echo "Configuring MySql"

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
crudini --set /etc/mysql/my.cnf mysqld log_error "/var/log/mysql/mysql.log"

service mysql restart

# Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
crudini --set /etc/mysql/my.cnf mysqld default_time_zone "UTC"

service mysql restart

echo "Configuring PHP"
crudini --set /etc/php/7.2/apache2/php.ini PHP allow_url_fopen "1"
crudini --set /etc/php/7.2/cli/php.ini PHP allow_url_fopen "1"

crudini --set /etc/php/7.2/apache2/php.ini PHP apc.entries_hint "524288"
crudini --set /etc/php/7.2/cli/php.ini PHP apc.entries_hint "524288"

crudini --set /etc/php/7.2/apache2/php.ini PHP apc.gc_ttl "600"
crudini --set /etc/php/7.2/cli/php.ini PHP apc.gc_ttl "600"

crudini --set /etc/php/7.2/apache2/php.ini PHP apc.shm_size "512M"
crudini --set /etc/php/7.2/cli/php.ini PHP apc.shm_size "512M"

crudini --set /etc/php/7.2/apache2/php.ini PHP apc.ttl "60"
crudini --set /etc/php/7.2/cli/php.ini PHP apc.ttl "60"

crudini --set /etc/php/7.2/apache2/php.ini PHP display_errors "1"
crudini --set /etc/php/7.2/cli/php.ini PHP display_errors "1"

crudini --set /etc/php/7.2/apache2/php.ini PHP display_startup_errors "0"
crudini --set /etc/php/7.2/cli/php.ini PHP display_startup_errors "0"

crudini --set /etc/php/7.2/apache2/php.ini PHP error_reporting "32767"
crudini --set /etc/php/7.2/cli/php.ini PHP error_reporting "32767"

crudini --set /etc/php/7.2/apache2/php.ini PHP html_errors "0"
crudini --set /etc/php/7.2/cli/php.ini PHP html_errors "0"

crudini --set /etc/php/7.2/apache2/php.ini PHP log_errors "1"
crudini --set /etc/php/7.2/cli/php.ini PHP log_errors "1"

crudini --set /etc/php/7.2/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/7.2/cli/php.ini PHP memory_limit "1024M"

crudini --set /etc/php/7.2/apache2/php.ini PHP opcache.enable "1"
crudini --set /etc/php/7.2/cli/php.ini PHP opcache.enable "1"

crudini --set /etc/php/7.2/apache2/php.ini PHP opcache.max_accelerated_files "10000"
crudini --set /etc/php/7.2/cli/php.ini PHP opcache.max_accelerated_files "10000"

crudini --set /etc/php/7.2/apache2/php.ini PHP opcache.memory_consumption "128"
crudini --set /etc/php/7.2/cli/php.ini PHP opcache.memory_consumption "128"

crudini --set /etc/php/7.2/apache2/php.ini PHP opcache.validate_timestamps "1"
crudini --set /etc/php/7.2/cli/php.ini PHP opcache.validate_timestamps "1"

crudini --set /etc/php/7.2/apache2/php.ini PHP post_max_size "64M"
crudini --set /etc/php/7.2/cli/php.ini PHP post_max_size "64M"

crudini --set /etc/php/7.2/apache2/php.ini PHP upload_max_filesize "64M"
crudini --set /etc/php/7.2/cli/php.ini PHP upload_max_filesize "64M"

crudini --set /etc/php/7.2/apache2/php.ini PHP memory_limit "1024M"
crudini --set /etc/php/7.2/cli/php.ini PHP memory_limit "1024M"

touch /etc/php/7.2/mods-available/sync.ini
echo "extension=sync.so" > /etc/php/7.2/mods-available/sync.ini
ln -s /etc/php/7.2/mods-available/sync.ini /etc/php/7.2/apache2/conf.d/sync.ini
ln -s /etc/php/7.2/mods-available/sync.ini /etc/php/7.2/cli/conf.d/sync.ini

# Restart all service
service apache2 restart
service mysql restart
service memcached restart

mkdir -p ${unix_workspace}/install_tmp

echo "Checkouting templates files for configuring system"
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp

# path to templates
templates=${unix_workspace}/install_tmp/templates

if [[ ! -d "$templates" ]]; then
  svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp
  if [[ ! -d "$templates" ]]; then
    check_result 1 "Error while checkouting templates"
  fi
fi

git clone https://github.com/wellnessliving/wl-sdk.git ${unix_workspace}/wl-sdk

crudini --set /etc/wsl.conf automount options '"metadata"'

# Setting config apache for site
PATH_APACHE="/etc/apache2/sites-available"

for project in ${a_site}; do
  document_root=${unix_workspace}/${project}/public_html

  if [[ "$project" == "wl.trunk" ]]; then
    host=${host_trunk}
  elif [[ "$project" == "wl.stable" ]]; then
    host=${host_stable}
  elif [[ "$project" == "wl.production" ]]; then
    host=${host_production}
  elif [[ "$project" == "studio.trunk" ]]; then
    host=${host_studio}
  fi

  sed -e "s;%server_alias%;${host};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host}.conf"
  a2ensite "${host}.conf"
done

# Create script to run services
cp ${templates}/sh/server.sh /root/server.sh
cp ${templates}/sh/clear.sh /root/clear.sh

# Create script to dump DB and restore db.
sed -e "
s;%workspace%;${unix_workspace};g
s;%mysql_user%;${db_login};g
s;%mysql_password%;${db_password};g
" ${templates}/sh/dump.sh > /root/dump.sh

sed -e "
s;%workspace%;${unix_workspace};g
s;%mysql_user%;${db_login};g
s;%mysql_password%;${db_password};g
" ${templates}/sh/restore.sh > /root/restore.sh
crudini --set ~/.my.conf mysqldump user root
crudini --set ~/.my.conf mysqldump password "${db_password}"

# a2enmod & a2enconf
a2enmod rewrite

# Create new DB user
mysql -uroot -e "create user '${db_login}'@'localhost' identified with mysql_native_password by '${db_password}';"
mysql -uroot -e "create user '${db_login}_read'@'localhost' identified with mysql_native_password by '${db_password}';"

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger"

mysql -uroot -e "create database a_geo;"
mysql -uroot -e "grant ${a_privileges} on a_geo.* to '${db_login}'@'localhost';"
mysql -uroot -e "grant select on a_geo.* to '${db_login}_read'@'localhost';"

# Creating databases
for project in ${a_site}; do
  project=$(echo "$project" | sed -r 's/\./_/g')
  a_db_list="main control test_main test_geo test_shard_example_0 test_shard_example_1 test_create xa"

  s_prefix=$(echo "$project" | sed -r 's/_[a-z_]+//g')
  if [[ ${s_prefix} == "wl" ]]; then
    a_db_list+=" shard_business_0 shard_business_1 test_shard_business_0 test_shard_business_1 shard_report_0 shard_report_1 test_shard_report_0 test_shard_report_1"
  fi

  for db_name in ${a_db_list}; do
    mysql -uroot -e "create database ${project}_${db_name};"
    mysql -uroot -e "grant ${a_privileges} on ${project}_${db_name}.* to '${db_login}'@'localhost';"
    mysql -uroot -e "grant select on ${project}_${db_name}.* to '${db_login}_read'@'localhost';"
  done
done
mysql -uroot -e "flush privileges;"

if [[ "$checkout" = 'yes' ]]; then
  echo -e "${Purple}#----------------------------------------------------------#
#                    Checkout projects                     #
#----------------------------------------------------------#${NC}"

  # Shared
  svn co "svn+libs://libs.svn.1024.info/shared" "${unix_workspace}/shared"

  if [[ ! -z "$host_trunk" ]]; then
    # Trunk
    svn co "svn+libs://libs.svn.1024.info/core/trunk" "${unix_workspace}/wl.trunk/core" # Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${unix_workspace}/wl.trunk/namespace.Core" # namespace.Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "${unix_workspace}/wl.trunk/namespace.Social" # namespace.Social
    svn co "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "${unix_workspace}/wl.trunk/namespace.Wl" # namespace.Wl
    svn co "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "${unix_workspace}/wl.trunk/project" # project
  fi

  if [[ ! -z "$host_stable" ]]; then
    # Stable
    svn co "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "${unix_workspace}/wl.stable/core" # Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "${unix_workspace}/wl.stable/namespace.Core" # namespace.Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "${unix_workspace}/wl.stable/namespace.Social" # namespace.Social
    svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "${unix_workspace}/wl.stable/namespace.Wl" # namespace.Wl
    svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "${unix_workspace}/wl.stable/project" # project
  fi

  if [[ ! -z "$host_production" ]]; then
    # Production
    svn co "svn+libs://libs.svn.1024.info/core/servers/www.wellnessliving.com" "${unix_workspace}/wl.production/core" # Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-production" "${unix_workspace}/wl.production/namespace.Core" # namespace.Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-production" "${unix_workspace}/wl.production/namespace.Social" # namespace.Social
    svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/production" "${unix_workspace}/wl.production/namespace.Wl" # namespace.Wl
    svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/production" "${unix_workspace}/wl.production/project" # project
  fi

  if [[ ! -z "$host_studio" ]]; then
    # Studio
    svn co "svn+libs://libs.svn.1024.info/core/trunk" "${unix_workspace}/studio.trunk/core" # Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${unix_workspace}/studio.trunk/namespace.Core" # namespace.Core
    svn co "svn+libs://libs.svn.1024.info/namespace/Studio/trunk" "${unix_workspace}/studio.trunk/namespace.Studio" # namespace.Studio
    svn co "svn+libs://libs.svn.1024.info/dev.1024.info/trunk" "${unix_workspace}/studio.trunk/project" # project
  fi
fi

sed -e "
s;{host_trunk};${host_trunk};g
s;{host_stable};${host_stable};g
s;{host_production};${host_production};g
s;{host_studio};${host_studio};g
s;{workspace};${win_workspace_slash};g
" ${templates}/windows/install.bat > "${unix_workspace}/install.bat"

# Creating link
echo -e "Open the workspace folder: '${Yellow}${win_workspace}${NC}' and run file '${Yellow}install.bat${NC}' as admin."
echo -e "Wait for run file..."
while [[ ! -f "${unix_workspace}/install.bat.done" ]];
do
  sleep 2
done
rm -f ${unix_workspace}/install.bat
rm -f ${unix_workspace}/install.bat.done

echo -e "${Purple}#----------------------------------------------------------#
#                  Setting default files                   #
#----------------------------------------------------------#${NC}"

for project in ${a_site}; do
  path_htprivate="${unix_workspace}/${project}/.htprivate"

  ALL_MAIN="rs"
  s_addr_template=${templates}/options/addr.wl.php
  s_config_template=${templates}/.config/a.test.wl.php
  s_db_template=${templates}/options/db.wl.php
  s_options_template=${templates}/options/options.wl.php
  if [[ "$project" == "wl.trunk" ]]; then
    host=${host_trunk}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigTrunkDeveloper"
  elif [[ "$project" == "wl.stable" ]]; then
    host=${host_stable}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigStableDeveloper"
  elif [[ "$project" == "wl.production" ]]; then
    host=${host_production}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigProductionDeveloper"
  elif [[ "$project" == "studio.trunk" ]]; then
    host=${host_studio}
    ALL_MAIN="studio"
    s_addr_template=${templates}/options/addr.studio.php
    s_config_template=${templates}/.config/a.test.studio.php
    s_db_template=${templates}/options/db.studio.php
    s_options_template=${templates}/options/options.studio.php
  fi

  # public_html/index.php
  sed -e "
  s;%path_htprivate%;${path_htprivate};g
  " ${templates}/public_html/index.php > "${unix_workspace}/${project}/public_html/index.php"

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

  ADDR_PATH_TOP="${path_htprivate}/"
  ADDR_PATH_WORKSPACE="${unix_workspace}/${project}/"
  A_TEST_XML_XSD="${unix_workspace}/shared/xsd/"
  ADDR_SECRET=$(gen_pass)
  PATH_PUBLIC="${unix_workspace}/${project}/public_html/"
  path_config=${unix_workspace}/${project}/project/.config
  mkdir -p -v ${path_config}

  # options/addr.php
  sed -e "
  s;%ALL_MAIN%;${ALL_MAIN};g
  s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g
  s;%ADDR_PATH_WORKSPACE%;${ADDR_PATH_WORKSPACE};g
  s;%WORKSPACE%;${unix_workspace};g
  s;%CLASS_INITIALIZE%;${CLASS_INITIALIZE};g
  s;%A_TEST_XML_XSD%;${A_TEST_XML_XSD};g
  s;%ADDR_SECRET%;${ADDR_SECRET};g
  s;%email%;${email};g
  s;%bot_login%;${bot_login};g
  s;%bot_password%;${bot_password};g
  s;%prg_login%;${prg_login};g
  s;%prg_password%;${prg_password};g
  s;%ADDR_URL_SERVER%;${host};g
  s;%PATH_PUBLIC%;${PATH_PUBLIC};g
  " ${s_addr_template} > "${path_htprivate}/options/addr.php"

  project_db=$(echo "$project" | sed -r 's/\./_/g')

  # options/db.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project_db};g
  " ${s_db_template} > "${path_htprivate}/options/db.php"

  #.config/a.test.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project_db};g
  s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g
  " ${s_config_template} > "${path_config}/a.test.php"
done

cp -a ${templates}/windows/selenium/ ${unix_workspace}

echo -e "${Purple}#----------------------------------------------------------#
#                     Update Database                      #
#----------------------------------------------------------#${NC}"
max_attempt=5
i_attempt=0
# Update DB
for project in ${a_site}; do
  options=${unix_workspace}/${project}/.htprivate/options

  echo "Clearing cache for ${project}"
  php ${options}/cli.php cms.cache.clear
  rm -rf ${unix_workspace}/${project}/.htprivate/writable/cache
  echo

  echo "Update main DB for ${project}"
  while [[ ${i_attempt} -lt ${max_attempt} ]];
  do
    php ${options}/cli.php db.update # Main database
    if [[ "$?" -eq 0 ]]; then
      break
    fi
    i_attempt=$((i_attempt+1))
  done
  echo

  i_attempt=0
  echo "Update test DB for ${project}"
  while [[ ${i_attempt} -lt ${max_attempt} ]];
  do
    php ${options}/cli.php db.update a # Test database
    if [[ "$?" -eq 0 ]]; then
      break
    fi
    i_attempt=$((i_attempt+1))
  done
  i_attempt=0
  echo

  echo "Update messages for ${project}"
  php ${options}/cli.php cms.message.update
  echo
  echo
done


rm -rf ${unix_workspace}/install_tmp

# Add service to start system
# Maybe not work on WSL
update-rc.d apache2 defaults
update-rc.d mysql defaults
update-rc.d memcached defaults

# Restart all service
service apache2 restart
service mysql restart
service memcached restart
service gearman-job-server start

echo -e "${Green}
Installation finished successfully.

Programmer's page(PRG):

    PRG username: ${prg_login}
    PRG password: ${prg_password}

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
