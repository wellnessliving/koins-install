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
export PYTHONIOENCODING=utf8 # Needed to decode json

software="crudini mysql-server-8.0 git aptitude"
software+=" apache2 php8.2 php8.2-dev php-pear php8.2-bcmath php8.2-xml php8.2-curl"
software+=" php8.2-gd php8.2-mbstring php8.2-mysql php8.2-soap php8.2-tidy php8.2-zip"
software+=" php8.2-apcu php8.2-memcache memcached libneon27-gnutls libserf-1-1 jq subversion npm nodejs libaio1 libaio-dev gearman php8.2-gearman"

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
  -g, --checkout            Checkout projects     [yes|no] default: yes
  -x, --xdebug              Install xDebug        [yes|no] default: yes
  -w, --workspace           Path to workspace              default: /mnt/c/Workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -p, --production          Hostname for production
  -k, --studio              Hostname for studio
  -f, --force               Force installing
  -i, --ignore-installed    Ignore already installed packages
  -h, --help                Print this help

  Example simple: bash $0 --bot-login BotLogin
  Use form to generate install command: http://output.jsbin.com/feguzef"
  exit 1
}

# Translating argument to --gnu-long-options
for arg; do
  delimiter=""
  case "$arg" in
    --bot-login)        args="${args}-b " ;;
    --db-login)         args="${args}-d " ;;
    --db-password)      args="${args}-c " ;;
    --prg-login)        args="${args}-l " ;;
    --checkout)         args="${args}-g " ;;
    --xdebug)           args="${args}-x " ;;
    --workspace)        args="${args}-w " ;;
    --trunk)            args="${args}-t " ;;
    --stable)           args="${args}-s " ;;
    --production)       args="${args}-p " ;;
    --studio)           args="${args}-k " ;;
    --force)            args="${args}-f " ;;
    --ignore-installed) args="${args}-i " ;;
    --help)             args="${args}-h " ;;
    *)                  [[ "${arg:0:1}" == "-" ]] || delimiter="\""
                        args="${args}${delimiter}${arg}${delimiter} ";;
  esac
done
eval set -- "${args}"

# Parsing arguments
while getopts "b:s:k:p:d:c:l:g:x:w:t:fih" Option; do
  case ${Option} in
    b) bot_login=$OPTARG ;;        # Bot login
    d) db_login=$OPTARG ;;         # Login for DB
    c) db_password=$OPTARG ;;      # Password for DB
    l) prg_login=$OPTARG ;;        # Login for PRG
    g) checkout=$OPTARG ;;         # Checkout projects
    x) xdebug=$OPTARG ;;           # Checkout projects
    w) workspace=$OPTARG ;;        # Path to workspace
    t) host_trunk=$OPTARG ;;       # Hostname for trunk
    s) host_stable=$OPTARG ;;      # Hostname for stable
    p) host_production=$OPTARG ;;  # Hostname for production
    k) host_studio=$OPTARG ;;      # Hostname for studio
    f) force='yes' ;;              # Force installation
    i) ignore_installed='yes' ;;   # Ignore installed packages
    h) help_message ;;             # Help
    *) help_message ;;             # Print help (default)
  esac
done

# Setting default value for arguments
set_default_value 'db_login' 'koins'
set_default_value 'db_password' 'lkchpy91'
set_default_value 'prg_login' 'admin'
set_default_value 'checkout' 'yes'
set_default_value 'xdebug' 'yes'
set_default_value 'workspace' '/mnt/c/Workspace'
set_default_value 'host_trunk' 'wellnessliving.local'
set_default_value 'host_stable' 'stable.wellnessliving.local'

if [[ "${host_trunk}" == "${host_stable}" ]] || [[ "${host_trunk}" == "${host_production}" ]] || [[ "${host_trunk}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

if [[ "${host_stable}" == "${host_production}" ]] || [[ "${host_stable}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

if [[ -n "$host_production" ]] && [[ -n "$host_studio" ]] && [[ "${host_production}" == "${host_studio}" ]]; then
  check_result 1 "You must use different hostnames for each site."
fi

printf "Checking set argument --bot-login: "
if [[ -z "${bot_login}" ]]; then
  check_result 1 "Bot login not set. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-login: "
if [[ -z "${db_login}" ]]; then
  check_result 1 "DB login not set or empty. Try 'bash $0 --help' for more information."
fi
if [[ "${db_login}" == "root" ]]; then
  check_result 1 "DB login must not be root. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

printf "Checking set argument --db-password: "
if [[ -z "${db_password}" ]]; then
  check_result 1 "DB password not set or empty. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

if [[ ${workspace: -1} == "/" ]]; then
  workspace=${workspace::-1}
fi

printf "Checking path workspace: "
if [[ -d "${workspace:0:6}" ]]; then # workspace=/mnt/c/Workspace   ${workspace:0:6}=> /mnt/c
  mkdir -p -v "${workspace}"
  if [[ -n "$(ls -A "${workspace}")" ]]; then
    if [[ "$checkout" == "yes" ]]; then
      if [[ -z "$force" ]]; then
        echo -e "${Red} Directory ${workspace} not empty. Please, clean up folder ${workspace} ${NC} or use argument --force for automatic cleanup"
        exit 1
      fi
      echo -e "${Red}Force installing into non-empty folder ${workspace}${NC}"
    fi
  fi
else
  check_result 1 "Path ${workspace:0:6} not found."
  exit 1
fi
echo "[OK]"
echo 'Warning: Full system update will be triggered, some new ppa/packages installed'
if [[ $ignore_installed ]]; then
  echo "Ignoring packages already installed..."
else
  echo "Checking installed packages..."
  tmpfile=$(mktemp -p /tmp)
  conflicts=''
  dpkg --get-selections > "${tmpfile}"
  for pkg in mysql-server apache2 php8.2; do
  if grep -q ${pkg} "${tmpfile}"; then
      conflicts="$pkg $conflicts"
    fi
  done
  rm -f "${tmpfile}"

  # Conflict checking
  if [[ -n "$conflicts" ]] && [[ -z "$force" ]]; then
    echo -e "${Yellow} !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!"
    echo
    echo -e "The following packages are already installed:"
    echo -e "${conflicts}"
    echo
    echo "You could probably remove them, since some configuration options would be"
    echo "force-updated by the installation script and that could guide to conflicts."
    echo "Alternately, use --ignore-installed flag to proceed anyway"
    echo
    echo -e "!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!${NC}"
    echo
    check_result 1 "System should be installed on clean server."
  fi
fi

printf "Install packages:\n* "
echo "${software}" | sed -E -e 's/[[:blank:]]+/\n* /g' # Replace space to newline
echo "Install xDebug: ${xdebug}"
echo "Checkout projects: ${checkout}"
echo "Workspace: ${workspace}"
echo "Login for PRG: ${prg_login}"
echo "Login for DB: ${db_login}"
echo "Password for DB: ${db_password}"
echo "Host for trunk: ${host_trunk}"
echo "Host for stable: ${host_stable}"
echo "Host for production: ${host_production}"
echo "Host for studio: ${host_studio}"
echo

# Asking for confirmation to proceed
read -rp 'Would you like to continue [y/N]: ' answer
if [[ "$answer" != 'y' ]] && [[ "$answer" != 'Y'  ]]; then
  echo -e 'Install cancelled by user. Goodbye'
  exit 1
fi

a_site=""

# Folders for trunk
if [[ -n "$host_trunk" ]]; then
  a_site+=" wl.trunk"
fi

# Folders for studio
if [[ -n "$host_stable" ]]; then
  a_site+=" wl.stable"
fi

# Folders for production
if [[ -n "$host_production" ]]; then
  a_site+=" wl.production"
fi

# Folders for studio
if [[ -n "$host_studio" ]]; then
  a_site+=" studio.trunk"
fi

if [[ -z "${a_site}" ]]; then
  check_result 1 "You must select at least one site."
fi

printf "Creating file structure: "

mkdir -p "${workspace}/keys"
mkdir -p "${workspace}/less/4.1.3"

for project in ${a_site}; do
  mkdir -p "${workspace}/${project}"/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
  chmod -R a+w "${workspace}/${project}/.htprivate/writable/"
  chmod -R a+w "${workspace}/${project}/public_html/"
done

echo "[OK]"

echo "Adding ppa:ondrej/..."
sudo add-apt-repository ppa:ondrej/php -y
sudo add-apt-repository ppa:ondrej/apache2 -y
#gearman repo doesn't have the files for Ubuntu 21.10 yet
#sudo add-apt-repository ppa:ondrej/pkg-gearman -y

echo -e "${Purple}#----------------------------------------------------------#
#               Checking for package updates               #
#----------------------------------------------------------#${NC}"
sudo apt-get update
check_result $? 'apt-get update failed'

echo -e "${Purple}#----------------------------------------------------------#
#                    Upgrading packages                    #
#----------------------------------------------------------#${NC}"
sudo apt-get -y upgrade
check_result $? 'apt-get upgrade failed'

echo -e "${Purple}#----------------------------------------------------------#
#           Installing packages and dependencies            #
#----------------------------------------------------------#${NC}"
sudo apt-get -y install ${software}
check_result $? "apt-get install failed"

echo "In the following prompt please select php 8.2 as your default php version (version php8.1+ is not supported yet): "
sudo update-alternatives --config php

cd "${workspace}/less/4.1.3" && npm install less@4.1.3

# Install Pecl and Sync extension.
sudo pecl install sync
echo "extension=sync.so" | sudo tee /etc/php/8.2/mods-available/sync.ini > /dev/null
sudo ln -s /etc/php/8.2/mods-available/sync.ini /etc/php/8.2/apache2/conf.d/sync.ini
sudo ln -s /etc/php/8.2/mods-available/sync.ini /etc/php/8.2/cli/conf.d/sync.ini

sudo pecl install yac
touch /etc/php/8.2/mods-available/yac.ini
echo "extension=yac.so" > /etc/php/8.2/mods-available/yac.ini
ln -s /etc/php/8.2/mods-available/yac.ini /etc/php/8.2/apache2/conf.d/yac.ini
ln -s /etc/php/8.2/mods-available/yac.ini /etc/php/8.2/cli/conf.d/yac.ini

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"
status=""
while [ "$status" != "ok" ]; do
  read -rp 'Write one time password from studio: ' one_time_password

  tmp_repository_file=$(mktemp -p /tmp)
  curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Key.json' -X POST --data "s_login=${bot_login}&s_user_password=${one_time_password}&s_repository=libs" -o "${tmp_repository_file}"

  status=$(jq -M -r '.status' "${tmp_repository_file}")

  if [[ "$status" != 'ok' ]]; then
    message=$(jq -M -r '.message' "${tmp_repository_file}")
    echo "Error getting repository key: ${message}"
    echo "Status: ${status}"
    echo "${tmp_repository_file}"
    echo
    read -rp 'Try again?[y/n]: ' answer
    if [[ "$answer" = 'n' ]] || [[ "$answer" = 'N'  ]]; then
      exit 1
    fi
  fi
done

private_key=$(jq -M '.s_private' "${tmp_repository_file}")
passphrase=$(jq -M '.s_password' "${tmp_repository_file}")

tmp_repository_key=$(mktemp -p /tmp)
tmp_repository_passphrase=$(mktemp -p /tmp)

echo "${private_key}" > "${tmp_repository_key}"
sed -i 's/\\n/\n/g' "${tmp_repository_key}"
sed -i 's/"//g' "${tmp_repository_key}"

echo "${passphrase}" > "${tmp_repository_passphrase}"
sed -i 's/"//g' "${tmp_repository_passphrase}"

cp "${tmp_repository_key}" "${workspace}/keys/libs.key"
key=${workspace}/keys/libs.key
passphrase=$(cat "${tmp_repository_passphrase}")

rm -f "${tmp_repository_key}"
rm -f "${tmp_repository_passphrase}"
rm -f "${tmp_repository_file}"

if [[ ${key: -1} == "/" ]]; then
  key=${key::-1}
fi

printf "Checking set argument --key: "
if [[ -n "${key}" ]]; then
  if [[ ! -f ${key} ]]; then
    check_result 1 "No such key file"
  fi
  echo "[OK]"
  printf "Checking set argument --passphrase: "
  if [[ -n "${passphrase}" ]]; then
    echo "[OK]"
    echo "Decrypting key..."
    cp "${key}" ~/.ssh/libs.key
    chmod 600 ~/.ssh/libs.key
    openssl rsa -in ~/.ssh/libs.key -out ~/.ssh/libs.pub -passin "pass:${passphrase}"
    check_result $? 'Decrypt key error'
    chmod 600 ~/.ssh/libs.pub
  else
    check_result 1 "Passphrase for key not set. Try 'bash $0 --help' for more information."
  fi
else
  check_result 1 "Key not set."
fi

status=""
while [ "$status" != "ok" ]; do
  read -rp 'Write one time password from studio: ' one_time_password
  if [[ -z "$one_time_password" ]]; then
    continue
  fi

  tmp_user_file=$(mktemp -p /tmp)

  curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Detail/Detail.json' -X POST --data "s_login=${bot_login}&s_user_password=${one_time_password}" -o "${tmp_user_file}"

  status=$(jq -M -r '.status' "${tmp_user_file}")

  if [[ "$status" != 'ok' ]]; then
    message=$(jq -M -r '.message' "${tmp_user_file}")
    echo "Error getting repository key: ${message}"
    echo "Status: ${status}"
    echo "${tmp_repository_file}"
    echo
    read -rp 'Try again?[y/n]: ' answer
    if [[ "$answer" = 'n' ]] || [[ "$answer" = 'N'  ]]; then
      exit 1
    fi
  fi
done

email=$(jq -M -r '.text_mail' "${tmp_user_file}")
bot_password=$(jq -M -r '.s_bot_password' "${tmp_user_file}")
rm -f "${tmp_user_file}"

# Add option AcceptFilter to config Apache and restart apache2
echo -e "
AcceptFilter http none" | sudo tee -a /etc/apache2/apache2.conf > /dev/null

# Configure xdebug
if [[ "$xdebug" == "yes" ]]; then
  sudo apt-get -y install php8.2-xdebug
  sudo crudini --set /etc/php/8.2/apache2/conf.d/20-xdebug.ini "" "zend_extension" "xdebug.so"
  sudo crudini --set /etc/php/8.2/apache2/conf.d/20-xdebug.ini "" "xdebug.mode" "debug"
  sudo crudini --set /etc/php/8.2/apache2/conf.d/20-xdebug.ini "" "xdebug.start_with_request" "trigger"
  sudo crudini --set /etc/php/8.2/apache2/conf.d/20-xdebug.ini "" "xdebug.idekey" "PHPSTORM"
  sudo crudini --set /etc/php/8.2/apache2/conf.d/20-xdebug.ini "" "xdebug.max_nesting_level" "-1"

  sudo systemctl restart apache2
fi

# Configuring svn
svn info
printf "Configuring SVN: "
sudo crudini --set ~/.subversion/config tunnels libs "ssh svn@libs.svn.1024.info -p 35469 -i ~/.ssh/libs.pub"

echo "Configuring MySql"

sudo crudini --set /etc/mysql/my.cnf mysqld sql_mode ""
sudo crudini --set /etc/mysql/my.cnf mysqld character_set_server "binary"
sudo crudini --set /etc/mysql/my.cnf mysqld log_bin "0"
sudo crudini --set /etc/mysql/my.cnf mysqld log_bin_trust_function_creators "ON"
sudo crudini --set /etc/mysql/my.cnf mysqld max_allowed_packet "104857600"
sudo crudini --set /etc/mysql/my.cnf mysqld innodb_flush_log_at_timeout "60"
sudo crudini --set /etc/mysql/my.cnf mysqld innodb_flush_log_at_trx_commit "0"
sudo crudini --set /etc/mysql/my.cnf mysqld default_authentication_plugin "mysql_native_password"
sudo crudini --set /etc/mysql/my.cnf mysqld innodb_use_native_aio "off"
sudo crudini --set /etc/mysql/my.cnf mysqld log_error "/var/log/mysql/mysql.log"
sudo crudini --set /etc/mysql/my.cnf mysqld expire_logs_days "1"
sudo crudini --set /etc/mysql/my.cnf mysqld binlog_order_commits "0"

sudo systemctl restart mysql

# Load timezone to mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql mysql
sudo crudini --set /etc/mysql/my.cnf mysqld default_time_zone "UTC"

sudo systemctl restart mysql

echo "Configuring PHP"
sudo crudini --set /etc/php/8.2/apache2/php.ini PHP allow_url_fopen "1"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP allow_url_fopen "1"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP apc.entries_hint "524288"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP apc.entries_hint "524288"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP apc.gc_ttl "600"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP apc.gc_ttl "600"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP apc.shm_size "512M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP apc.shm_size "512M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP apc.ttl "60"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP apc.ttl "60"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP display_errors "1"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP display_errors "1"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP display_startup_errors "0"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP display_startup_errors "0"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP error_reporting "32767"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP error_reporting "32767"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP html_errors "0"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP html_errors "0"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP log_errors "1"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP log_errors "1"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP memory_limit "1024M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP memory_limit "1024M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.enable "1"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP opcache.enable "1"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.max_accelerated_files "10000"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP opcache.max_accelerated_files "10000"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.memory_consumption "128"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP opcache.memory_consumption "128"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP opcache.validate_timestamps "1"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP opcache.validate_timestamps "1"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP post_max_size "64M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP post_max_size "64M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP upload_max_filesize "64M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP upload_max_filesize "64M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP memory_limit "1024M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP memory_limit "1024M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP pcre.jit "0"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP pcre.jit "0"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP post_max_size "64M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP post_max_size "64M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP upload_max_filesize "64M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP upload_max_filesize "64M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP memory_limit "1024M"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP memory_limit "1024M"

sudo crudini --set /etc/php/8.2/apache2/php.ini PHP pcre.jit "0"
sudo crudini --set /etc/php/8.2/cli/php.ini PHP pcre.jit "0"

# Restart all services
sudo systemctl restart apache2
sudo systemctl restart mysql
sudo systemctl restart memcached

mkdir -p "${workspace}/install_tmp"
echo "Checking out template files for system configuration"
svn co --quiet svn+libs://libs.svn.1024.info/reservationspot.com/install "${workspace}/install_tmp"

install_tmp=${workspace}/install_tmp
# path to templates
templates=${install_tmp}/templates

if [[ ! -d "$templates" ]]; then
  svn co --quiet svn+libs://libs.svn.1024.info/reservationspot.com/install "${workspace}/install_tmp"
  if [[ ! -d "$templates" ]]; then
    check_result 1 "Error while checking out templates"
  fi
fi

git clone https://github.com/wellnessliving/wl-sdk.git "${workspace}/wl-sdk"

# Setting config apache for site
PATH_APACHE="/etc/apache2/sites-available"

for project in ${a_site}; do
  document_root=${workspace}/${project}/public_html

  if [[ "$project" == "wl.trunk" ]]; then
    host=${host_trunk}
  elif [[ "$project" == "wl.stable" ]]; then
    host=${host_stable}
  elif [[ "$project" == "wl.production" ]]; then
    host=${host_production}
  elif [[ "$project" == "studio.trunk" ]]; then
    host=${host_studio}
  fi

  sed -e "s;%server_alias%;${host};g" -e "s;%document_root%;${document_root};g" "${templates}/apache2/site.conf" | sudo tee "${PATH_APACHE}/${host}.conf" > /dev/null
  sudo a2ensite "${host}.conf"
done

# Create script to run services
cp "${templates}/sh/server.sh" "${workspace}/server.sh"
cp "${templates}/sh/clear.sh" "${workspace}/clear.sh"

# Create script to dump DB and restore db.
sed -e "
s;%workspace%;${workspace};g
s;%mysql_user%;${db_login};g
s;%mysql_password%;${db_password};g
" "${templates}/sh/dump.sh" > "${workspace}/dump.sh"
chmod +x "${workspace}/dump.sh"

sed -e "
s;%workspace%;${workspace};g
s;%mysql_user%;${db_login};g
s;%mysql_password%;${db_password};g
" "${templates}/sh/restore.sh" > "${workspace}/restore.sh"
chmod +x "${workspace}/restore.sh"

sudo crudini --set ~/.my.conf mysqldump user "${db_login}"
sudo crudini --set ~/.my.conf mysqldump password "${db_password}"

# a2enmod & a2enconf
sudo a2enmod rewrite

# Create new DB user
sudo mysql -e "create user '${db_login}'@'localhost' identified with mysql_native_password by '${db_password}';"
sudo mysql -e "create user '${db_login}_read'@'localhost' identified with mysql_native_password by '${db_password}';"

a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger,create temporary tables,alter routine,create routine,execute"

sudo mysql -e "create database a_geo;"
sudo mysql -e "grant ${a_privileges} on a_geo.* to '${db_login}'@'localhost';"
sudo mysql -e "grant session_variables_admin on *.* to '${db_login}'@'localhost';"
sudo mysql -e "grant select on a_geo.* to '${db_login}_read'@'localhost';"

# Creating databases
for project in ${a_site}; do
  project=$(echo "$project" | sed -r 's/\./_/g')
  a_db_list="main control test_main test_geo test_shard_0 test_shard_1 test_create xa"

  s_prefix=$(echo "$project" | sed -r 's/_[a-z_]+//g')
  if [[ ${s_prefix} == "wl" ]]; then
    a_db_list+=" shard_0 shard_1"
  fi

  if [[ ${s_prefix} == "studio" ]]; then
    a_db_list+=" mail"
  fi

  for db_name in ${a_db_list}; do
    sudo mysql -e "create database ${project}_${db_name};"
    sudo mysql -e "grant ${a_privileges} on ${project}_${db_name}.* to '${db_login}'@'localhost';"
    sudo mysql -e "grant select on ${project}_${db_name}.* to '${db_login}_read'@'localhost';"
  done
done
sudo mysql -e "flush privileges;"

if [[ "$checkout" = 'yes' ]]; then
  echo -e "${Purple}#----------------------------------------------------------#
#                    Checking out projects                     #
#----------------------------------------------------------#${NC}"

  # Shared
  svn co --quiet "svn+libs://libs.svn.1024.info/shared" "${workspace}/shared"

  if [[ -n "$host_trunk" ]]; then
    # Trunk
    svn co --quiet "svn+libs://libs.svn.1024.info/core/trunk" "${workspace}/wl.trunk/core" # Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${workspace}/wl.trunk/namespace.Core" # namespace.Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "${workspace}/wl.trunk/namespace.Social" # namespace.Social
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "${workspace}/wl.trunk/namespace.Wl" # namespace.Wl
    svn co --quiet "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "${workspace}/wl.trunk/project" # project
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/Report/trunk" "${workspace}/wl.trunk/Thoth/Report" # Thoth Report
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/ReportCore/trunk" "${workspace}/wl.trunk/Thoth/ReportCore" # Thoth ReportCore
  fi

  if [[ -n "$host_stable" ]]; then
    # Stable
    svn co --quiet "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "${workspace}/wl.stable/core" # Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "${workspace}/wl.stable/namespace.Core" # namespace.Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "${workspace}/wl.stable/namespace.Social" # namespace.Social
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "${workspace}/wl.stable/namespace.Wl" # namespace.Wl
    svn co --quiet "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "${workspace}/wl.stable/project" # project
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/Report/servers/stable" "${workspace}/wl.stable/Thoth/Report" # Thoth Report
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/stable" "${workspace}/wl.stable/Thoth/ReportCore" # Thoth ReportCore

    # Stable Old
    svn co --quiet "svn+libs://libs.svn.1024.info/core/servers/stable-old" "${workspace}/wl.stable.old/core" # Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Core/servers/stable-old" "${workspace}/wl.stable.old/namespace.Core" # namespace.Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Social/servers/stable-old" "${workspace}/wl.stable.old/namespace.Social" # namespace.Social
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable-old" "${workspace}/wl.stable.old/namespace.Wl" # namespace.Wl
    svn co --quiet "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable-old" "${workspace}/wl.stable.old/project" # project
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/Report/servers/stable-old" "${workspace}/wl.stable.old/Thoth/Report" # Thoth Report
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/stable-old" "${workspace}/wl.stable.old/Thoth/ReportCore" # Thoth  ReportCore
  fi

  if [[ -n "$host_production" ]]; then
    # Production
    svn co --quiet "svn+libs://libs.svn.1024.info/core/servers/www.wellnessliving.com" "${workspace}/wl.production/core" # Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-production" "${workspace}/wl.production/namespace.Core" # namespace.Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-production" "${workspace}/wl.production/namespace.Social" # namespace.Social
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Wl/servers/production" "${workspace}/wl.production/namespace.Wl" # namespace.Wl
    svn co --quiet "svn+libs://libs.svn.1024.info/reservationspot.com/servers/production" "${workspace}/wl.production/project" # project
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/Report/servers/production" "${workspace}/wl.production/Thoth/Report" # Thoth Report
    svn co --quiet "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/production" "${workspace}/wl.production/Thoth/ReportCore" # Thoth ReportCore
  fi

  if [[ -n "$host_studio" ]]; then
    # Studio
    svn co --quiet "svn+libs://libs.svn.1024.info/core/trunk" "${workspace}/studio.trunk/core" # Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${workspace}/studio.trunk/namespace.Core" # namespace.Core
    svn co --quiet "svn+libs://libs.svn.1024.info/namespace/Studio/trunk" "${workspace}/studio.trunk/namespace.Studio" # namespace.Studio
    svn co --quiet "svn+libs://libs.svn.1024.info/dev.1024.info/trunk" "${workspace}/studio.trunk/project" # project
  fi
fi

echo "Adding host names to the /etc/hosts file"
echo -e "\n127.0.0.1 ${host_trunk} ${host_stable} ${host_production} ${host_studio}\n" | sudo tee -a /etc/hosts > /dev/null

echo -e "${Purple}#----------------------------------------------------------#
#                  Setting default files                   #
#----------------------------------------------------------#${NC}"

s_geo_host=$(crudini --get "${install_tmp}/config/geo.ini" connect host)
s_geo_login=$(crudini --get "${install_tmp}/config/geo.ini" connect login)
s_geo_name=$(crudini --get "${install_tmp}/config/geo.ini" connect name)
s_geo_password=$(crudini --get "${install_tmp}/config/geo.ini" connect password)
for project in ${a_site}; do
  path_htprivate="${workspace}/${project}/.htprivate"

  ALL_MAIN="rs"
  s_addr_template=${templates}/options/addr.wl.php
  s_config_template=${templates}/.config/a.test.wl.php
  s_db_template=${templates}/options/db.wl.php
  s_options_template=${templates}/options/options.wl.php
  if [[ "$project" == "wl.trunk" ]]; then
    host=${host_trunk}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigTrunkDeveloper"
    CONFIGURATION_NAME="trunk.developer"
  elif [[ "$project" == "wl.stable" ]]; then
    host=${host_stable}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigStableDeveloper"
    CONFIGURATION_NAME="staging.developer"
  elif [[ "$project" == "wl.production" ]]; then
    host=${host_production}
    CLASS_INITIALIZE="\\\Wl\\\Config\\\ConfigProductionDeveloper"
    CONFIGURATION_NAME="production.developer"
  elif [[ "$project" == "studio.trunk" ]]; then
    host=${host_studio}
    ALL_MAIN="studio"
    s_addr_template=${templates}/options/addr.studio.php
    s_config_template=${templates}/.config/a.test.studio.php
    s_db_template=${templates}/options/db.studio.php
    s_options_template=${templates}/options/options.studio.php
  fi

  # public_html/index.php
  cp ${templates}/public_html/index.php "${workspace}/${project}/public_html/index.php"

  # public_html/.htaccess
  sed -e "
  s;%workspace%;${workspace};g
  s;%project%;${project};g
  " "${templates}/public_html/.htaccess" > "${workspace}/${project}/public_html/.htaccess"

  # public_html/favicon.ico
  cp "${templates}/public_html/favicon.ico" "${workspace}/${project}/public_html/favicon.ico"

  cp "${s_options_template}" "${workspace}/${project}/.htprivate/options/options.php"
  cp "${templates}/options/inc.php" "${workspace}/${project}/.htprivate/options/inc.php"
  cp "${templates}/options/cli.php" "${workspace}/${project}/.htprivate/options/cli.php"

  ADDR_SECRET=$(gen_pass)
  path_config="${workspace}/${project}/project/.config"
  mkdir -p -v "${path_config}"

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
  " "${s_addr_template}" > "${path_htprivate}/options/addr.php"

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
  " "${s_db_template}" > "${path_htprivate}/options/db.php"

  #.config/a.test.php
  sed -e "
  s;%db_login%;${db_login};g
  s;%db_password%;${db_password};g
  s;%project%;${project_db};g
  " "${s_config_template} "> "${path_config}/a.test.php"

  sudo chmod -R 777 "${path_htprivate}/writable"
done

echo "Downloading Selenium"
cp -a "${templates}"/sh/selenium/ "${workspace}"
selenium_version=$(curl --silent "https://api.github.com/repos/SeleniumHQ/selenium/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
selenium_version_number=$(echo "$selenium_version" | sed -re 's/^.*-([\.0-9]+)$/\1/');
wget -nv "https://github.com/SeleniumHQ/selenium/releases/download/${selenium_version}/selenium-server-${selenium_version_number}.jar"
mv "selenium-server-${selenium_version_number}.jar" "${workspace}"/selenium/
ln -s "${workspace}/selenium/selenium-server-${selenium_version_number}.jar" "${workspace}/selenium/selenium-server.jar"
major_chrome_version=$(aptitude versions google-chrome-stable | grep -P '^i' | awk '{print $2}' | sed -re 's/^([0-9]+\.[0-9]+\.[0-9]+)\..*/\1/')
if [[ ! $major_chrome_version ]]; then
  echo "google-chrome-stable is not found installed in your system. Thus, compatible chromeDriver version can not be determined. Please download proper version using guide at https://chromedriver.chromium.org/downloads/version-selection and place it to the ${workspace}/selenium folder"
  read -rp "Press <enter> to continue"
else
  chrome_driver_version=$(curl "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${major_chrome_version}");
  wget -nv "https://chromedriver.storage.googleapis.com/$chrome_driver_version/chromedriver_linux64.zip"
  unzip chromedriver_linux64.zip
  mv chromedriver "${workspace}/selenium/"
  rm chromedriver_linux64.zip
fi

echo -e "${Purple}#----------------------------------------------------------#
#                     Updating Database                      #
#----------------------------------------------------------#${NC}"
max_attempt=5
i_attempt=0
# Update DB
for project in ${a_site}; do
  options="${workspace}/${project}/.htprivate/options"

  echo "Clearing cache for ${project}"
  "${workspace}/clear.sh" "${workspace}/${project}"

  is_update_ar=0
  while [[ ${is_update_ar} -eq 0 ]];
  do
    echo "Creating Active Record for ${project}"
    php "${options}/cli.php" "\\Core\\Db\\Ar\\Compile\\ArCompile"
    if [[ "$?" -eq 0 ]]; then
      is_update_ar=1
    else
      read -rp 'Active record is not created. Try creating again?[y/n]: ' answer
      if [[ "$answer" = 'n' ]] || [[ "$answer" = 'N'  ]]; then
        is_update_ar=1
      fi
    fi
  done

  echo "Update main DB for ${project}"
  while [[ ${i_attempt} -lt ${max_attempt} ]];
  do
    php "${options}/cli.php" db.update # Main database
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
    php "${options}/cli.php" db.update a # Test database
    if [[ "$?" -eq 0 ]]; then
      break
    fi
    i_attempt=$((i_attempt+1))
  done
  i_attempt=0
  echo

  echo "Update messages for ${project}"
  php "${options}/cli.php" cms.message.update
  echo
  echo
done

mkdir /dev/shm/demoTaskThread
sudo chown www-data:www-data /dev/shm/demoTaskThread
sudo chmod 777 /dev/shm/demoTaskThread/

mkdir /dev/shm/demoDebugRun
sudo chown www-data:www-data /dev/shm/demoDebugRun
sudo chmod 777 /dev/shm/demoDebugRun/

mkdir /dev/shm/stagingTaskThread
sudo chown www-data:www-data /dev/shm/stagingTaskThread
sudo chmod 777 /dev/shm/stagingTaskThread/

mkdir /dev/shm/stagingDebugRun
sudo chown www-data:www-data /dev/shm/stagingDebugRun
sudo chmod 777 /dev/shm/stagingDebugRun/

rm -rf "${install_tmp}"

# Add service to start system
# Maybe not work on WSL
sudo systemctl enable apache2
sudo systemctl enable mysql
sudo systemctl enable memcached

# Restart all service
sudo systemctl restart apache2
sudo systemctl restart mysql
sudo systemctl restart memcached
sudo systemctl start gearman-job-server

echo -e "${Green}
Installation finished successfully.

Programmer's page(PRG):

    PRG username: ${prg_login}

MySql:
    username: ${db_login}
    password: ${db_password}
"

echo -e "Created scripts:

    ${workspace}/server.sh  - To start or restart all services.
    ${workspace}/dump.sh    - To dump database.
    ${workspace}/restore.sh - To restore DB from backup files. It will ask for the storage folder on start.
    ${workspace}/clear.sh   - To clear all the project cache folders. Usage: ${workspace}/clear.sh <project_folder>
                              Example: ${workspace}/clear.sh ${workspace}/wl.trunk

Ensure that your wl.trunk directory and all its parents are searchable. To do it run chmod a+x on each of the parent directories.

Project checked-out at: ${workspace}
Key for repository 'libs' saved in ${workspace}/keys/libs.key${NC}"

exit 0