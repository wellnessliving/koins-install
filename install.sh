#!/bin/bash
# (c) Vladislav Kobzev, Apr 2018, kp42@ya.ru
# A script for install LAMP on Ubuntu, checkout project and setup
#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
#COLORS
# Reset color
NC='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

export DEBIAN_FRONTEND=noninteractive
software="mc mcedit apache2 mysql-server php7.1 php7.1-bcmath php7.1-xml php7.1-curl php7.1-gd php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-soap php7.1-tidy php7.1-zip php-apcu php-memcached memcached phpmyadmin crudini libneon27-gnutls dialog putty-tools  libserf-1-1"

subversion_17="http://launchpadlibrarian.net/161750374/subversion_1.7.14-1ubuntu2_amd64.deb" #Subversion 1.7 because SVN 1.8 not supported symlinks
libsvn1_17="http://launchpadlibrarian.net/161750375/libsvn1_1.7.14-1ubuntu2_amd64.deb" #Dependence for Subversion 1.7

# Defining return code check function
check_result(){
    if [ $1 -ne 0 ]; then
        echo -e "${Red} Error: $2 ${NC}"
        exit $1
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
  ${DIALOG}  --keep-tite --backtitle "Subversion checkouting" --title ${title} --gauge "Getting total file count... It will take some time." 7 120 < <(
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
  -w, --workspace           Path to workspace              default: /mnt/d/Workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 --key /path/to/key --passphrase PassPhrase --bot-password BotLogin --bot-login BotPassword --email you@email.com
  Use form for generate install command: http://kasp.me/install/index.html"
  exit 1
}

if [ ! -n "${BASH}" ]; then
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
set_default_value 'workspace' '/mnt/d/Workspace'
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

printf "Checking path workspace: "
if [ -d "${workspace:0:6}" ]; then #workspace=/mnt/d/Workspace   ${workspace:0:6}=> /mnt/d
  mkdir -p -v ${workspace}
  if [ ! -z "$(ls -A ${workspace})" ]; then
    if [ "$checkout" == "yes" ]; then
      if [ -z "$force" ]; then
        echo -e "${Red} Directory ${workspace} not empty. Please delete folder ${workspace} ${NC} or use argument --force"
        exit 1
      fi
      echo -e "${Red}Remove workspace folder...${NC}"
      rm -rf ${workspace}
    fi
  fi
else
  check_result 1 "Path ${workspace:0:6} not found."
  exit 1
fi
echo "[OK]"

printf "Checking set argument --key: "
if [ -n "${key}" ]; then
  if [ ! -f ${key} ]; then
    check_result 1 "No such key file"
  fi
  echo "[OK]"
  printf "Checking set argument --passphrase: "
  if [ -n "${passphrase}" ]; then
    echo "[OK]"
    echo "Decrypting key..."
    mkdir -p /root/.ssh
    cp ${key} /root/.ssh/libs.key
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
echo "Workspace: ${workspace}"
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
mkdir -p ${workspace}/{checkout,keys,.htprivate/{${host_trunk},${host_stable}},wl.trunk,wl.stable,public_html/{a/drive,static}}

for site in $(ls ${workspace}/.htprivate); do
  mkdir -p ${workspace}/.htprivate/${site}/{options,writable/{cache,debug,log,php,sql,tmp,var,templates}}
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

dpkg -i $(curl -O -s -w '%{filename_effective}' ${libsvn1_17})
dpkg -i $(curl -O -s -w '%{filename_effective}' ${subversion_17})

DIALOG=${DIALOG=dialog}

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"

svn auth
printf "Configuring SVN: "
crudini --set /root/.subversion/config tunnels libs "ssh svn@libs.svn.1024.info -p 35469 -i /root/.ssh/libs.pub"
cp -rf /root/.subversion ${workspace}/Subversion
cp -rf /root/.ssh/libs.key ${workspace}/keys/libs.key
tpm_old_passphrase=$(mktemp -p /tmp)
tmp_new_passphrase=$(mktemp -p /tmp)
printf ${passphrase} > ${tpm_old_passphrase}
puttygen ${workspace}/keys/libs.key -o ${workspace}/keys/libs.ppk --old-passphrase ${tpm_old_passphrase} --new-passphrase ${tmp_new_passphrase}
crudini --set ${workspace}/Subversion/config tunnels libs "plink.exe -P 35469 -l svn -i ../keys/libs.ppk libs.svn.1024.info"
rm -f ${tpm_old_passphrase}
rm -f ${tmp_new_passphrase}
echo "[OK]"
service ssh restart

echo "Checkouting templates files for configuring system"
rm -rf ${workspace}/checkout/reservationspot.com/install
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${workspace}/checkout/reservationspot.com/install

#path to templates
templates=${workspace}/checkout/reservationspot.com/install/templates

tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > ${tmpfile}
if [ ! -z "$(grep php7.2-cli ${tmpfile})" ]; then
  apt-get purge php7.2-cli -y
fi
rm -f ${tmpfile}

echo "Configuring phpMyAdmin..."
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf

#Add option AcceptFilter to config Apache
echo -e "
AcceptFilter http none" >> /etc/apache2/apache2.conf

#Create script to run services
touch ~/server.sh
echo "service apache2 start
service mysql start
service memcached start" > ~/server.sh

#Start all service
service apache2 start
service mysql start
service memcached start

# a2enmod
a2enmod rewrite
a2enconf phpmyadmin

#Seting config apache for site
PATH_APACHE="/etc/apache2/sites-available"
document_root=${workspace}/public_html

sed -e "s;%server_alias%;${host_trunk};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host_trunk}.conf"
a2ensite "${host_trunk}.conf"

sed -e "s;%server_alias%;${host_stable};g" -e "s;%document_root%;${document_root};g" ${templates}/apache2/site.conf > "${PATH_APACHE}/${host_stable}.conf"
a2ensite "${host_stable}.conf"

#Create new DB user
mysql -e "CREATE USER '${db_login}'@'localhost' IDENTIFIED BY '${db_password}';"

#Creating databases
for project in trunk stable; do
  mysql -e "CREATE DATABASE ${project}_wl_main;"
  mysql -e "GRANT alter,create,delete,drop,index,insert,lock tables,references,select,update ON ${project}_wl_main.* TO '${db_login}'@'localhost';"
  mysql -e "CREATE DATABASE ${project}_wl_geo;"
  mysql -e "GRANT alter,create,delete,drop,index,insert,lock tables,references,select,update ON ${project}_wl_geo.* TO '${db_login}'@'localhost';"
  mysql -e "CREATE DATABASE ${project}_wl_control;"
  mysql -e "GRANT alter,create,delete,drop,index,insert,lock tables,references,select,update ON ${project}_wl_control.* TO '${db_login}'@'localhost';"
  mysql -e "CREATE DATABASE ${project}_test_main;"
  mysql -e "GRANT alter,create,delete,drop,index,insert,lock tables,references,select,update ON ${project}_test_main.* TO '${db_login}'@'localhost';"
  mysql -e "CREATE DATABASE ${project}_test_geo;"
  mysql -e "GRANT alter,create,delete,drop,index,insert,lock tables,references,select,update ON ${project}_test_geo.* TO '${db_login}'@'localhost';"
done

mysql -e "FLUSH PRIVILEGES"

if [ "$checkout" = 'yes' ]; then
  echo -e "${Purple}#----------------------------------------------------------#
#                    Checkout projects                     #
#----------------------------------------------------------#${NC}"

  #Shared
  svn co svn+libs://libs.svn.1024.info/shared ${workspace}/checkout/shared
  checkout_dialog "shared" "svn+libs://libs.svn.1024.info/shared" "${workspace}/checkout/shared"

  #Trunk
  checkout_dialog "[trunk]core" "svn+libs://libs.svn.1024.info/core/trunk" "${workspace}/checkout/core/trunk" #Core

  checkout_dialog "[trunk]namespace.Core" "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${workspace}/checkout/namespace/Core/trunk" #namespace.Core

  checkout_dialog "[trunk]namespace.Social" "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "${workspace}/checkout/namespace/Social/trunk" #namespace.Social

  checkout_dialog "[trunk]namespace.Wl" "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "${workspace}/checkout/namespace/Wl/trunk" #namespace.Wl

  checkout_dialog "[trunk]project" "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "${workspace}/checkout/reservationspot.com/trunk" #project

  #Stable
  checkout_dialog "[stable]core" "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "${workspace}/checkout/core/servers/stable.wellnessliving.com" #Core

  checkout_dialog "[stable]namespace.Core" "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "${workspace}/checkout/namespace/Core/servers/wl-stable" #namespace.Core

  checkout_dialog "[stable]namespace.Social" "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "${workspace}/checkout/namespace/Social/servers/wl-stable" #namespace.Social

  checkout_dialog "[stable]namespace.Wl" "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "${workspace}/checkout/namespace/Wl/servers/stable" #namespace.Wl

  checkout_dialog "[stable]project" "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "${workspace}/checkout/reservationspot.com/servers/stable" #project
fi


sed -e "s;{host_trunk};${host_trunk};g" -e "s;{host_stable};${host_stable};g" ${templates}/windows/install.bat > "${workspace}/install.bat"

# Creating link
echo -e "Open the workspace folder: '${Yellow}${workspace}${NC}' and run file '${Yellow}install.bat${NC}' as admin."
echo -e "Wait for run file..."
while [ ! -L "${workspace}/wl.stable/project" ];
do
  sleep 2
done

echo -e "${Purple}#----------------------------------------------------------#
#                 Setuping default files                   #
#----------------------------------------------------------#${NC}"

#public_html
path_htprivate=${workspace}/.htprivate/
#public_html/index.php
sed -e "s;%path_htprivate%;${path_htprivate};g" -e "s;%host_trunk%;${host_trunk};g" -e "s;%host_stable%;${host_stable};g" ${templates}/public_html/index.php > "${workspace}/public_html/index.php"
#public_html/.htaccess
sed -e "s;%workspace%;${workspace};g" -e "s;%host_trunk%;${host_trunk};g" ${templates}/public_html/.htaccess > "${workspace}/public_html/.htaccess"
#public_html/favicon.ico
cp ${templates}/public_html/favicon.ico "${workspace}/public_html/favicon.ico"

#Options
for site in $(ls ${workspace}/.htprivate); do
  cp ${templates}/options/options.php ${workspace}/.htprivate/${site}/options/options.php
  cp ${templates}/options/inc.php ${workspace}/.htprivate/${site}/options/inc.php
  cp ${templates}/options/cli.php ${workspace}/.htprivate/${site}/options/cli.php
  cp ${templates}/options/a/cli.php ${workspace}/.htprivate/${site}/options/a/cli.php
done

for site in $(ls ${workspace}/.htprivate); do
  [ ${site} == ${host_trunk} ] && project="trunk" || project="stable"
  [ ${project} = "trunk" ] && ADDR_URL_SERVER=${host_trunk} || ADDR_URL_SERVER=${host_stable}

  ADDR_PATH_TOP="${workspace}/.htprivate/${ADDR_URL_SERVER}/"
  ADDR_PATH_WORKSPACE="${workspace}/wl.${project}/"
  A_TEST_XML_XSD="${workspace}/shared/xsd/"
  ADDR_SECRET=$(gen_pass)
  PATH_PUBLIC="${workspace}/public_html/"

  #options/addr.php
  sed -e "s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g" -e "s;%ADDR_PATH_WORKSPACE%;${ADDR_PATH_WORKSPACE};g" -e "s;%A_TEST_XML_XSD%;${A_TEST_XML_XSD};g" -e "s;%ADDR_SECRET%;${ADDR_SECRET};g" -e "s;%email%;${email};g" -e "s;%bot_login%;${bot_login};g" -e "s;%bot_password%;${bot_password};g" -e "s;%prg_login%;${prg_login};g" -e "s;%prg_password%;${prg_password};g" -e "s;%ADDR_URL_SERVER%;${ADDR_URL_SERVER};g" -e "s;%PATH_PUBLIC%;${PATH_PUBLIC};g" ${templates}/options/addr.php > "${workspace}/.htprivate/${ADDR_URL_SERVER}/options/addr.php"
  #options/db.php
  sed -e "s;%db_login%;${db_login};g" -e "s;%db_password%;${db_password};g" -e "s;%project%;${project};g" ${templates}/options/db.php > "${workspace}/.htprivate/${ADDR_URL_SERVER}/options/db.php"

  mkdir -p -v ${ADDR_PATH_WORKSPACE}/project/.config/
  config=${ADDR_PATH_WORKSPACE}/project/.config/
  #.config/a.test.php
  sed -e "s;%db_login%;${db_login};g" -e "s;%db_password%;${db_password};g" -e "s;%project%;${project};g" -e "s;%ADDR_PATH_TOP%;${ADDR_PATH_TOP};g" ${templates}/.config/a.test.php > "${config}/a.test.php"
  #.config/amazon.php
  cp ${templates}/.config/amazon.php "${config}/amazon.php"
done


echo -e "${Purple}#----------------------------------------------------------#
#                     Update Database                      #
#----------------------------------------------------------#${NC}"
#Update DB
for site in $(ls ${workspace}/.htprivate); do
  options=${workspace}/.htprivate/${site}/options
  echo "Update main DB for ${site}"
  php ${options}/cli.php db.update #Main
  echo "Update test DB for ${site}"
  php ${options}/a-cli.php db.update a #Test

  writable=${workspace}/.htprivate/${site}/writable
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

Project checkout  on the path ${workspace}

Key for repository 'libs' saved in %Workspace%/keys/libs.key
Configs for Subversion created for PHPStorm 2018 in %Workspace%/Subversion
For work Subversion in PHPStorm 2018 you need downloads 'Subversion for Windows <=1.7.9' and 'Putty'
Subversion: https://sourceforge.net/projects/win32svn/files/1.7.9/apache22/Setup-Subversion-1.7.9.msi/download

Go to PHPStorm adn setup SVN.
1. File -> Settings -> Version Control -> Subversion
2. Set check mark  'Use custom configuration directory'
3. Select directory %Workspace%/Subversion

1. VCS -> Browse VCS Repository -> Browse Subversion Repository
2. Add new repository: 'svn+libs://libs.svn.1024.info'
${NC}"

exit 0
