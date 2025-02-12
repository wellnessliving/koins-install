#!/bin/bash

#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/${USER}/.zprofile
#eval "$(/opt/homebrew/bin/brew shellenv)"
#
#brew install svn
#brew install jq
#brew install gnu-sed
#PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

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

# Defining help function
help_message() {
  echo -e "Usage: $0 [OPTIONS]
  -b, --bot-login           Bot login                      required
  -d, --db-login            Login for DB                   default: koins
  -c, --db-password         Password for DB                default: lkchpy91
  -l, --prg-login           Login for PRG                  default: admin
  -g, --checkout            Checkout projects     [yes|no] default: yes
  -w, --workspace           Path to workspace
  -t, --trunk               Hostname for trunk             default: wellnessliving.local
  -s, --stable              Hostname for stable            default: stable.wellnessliving.local
  -p, --production          Hostname for production        default: production.wellnessliving.local
  -k, --studio              Hostname for studio            default: studio.tr
  -f, --force               Force installing
  -h, --help                Print this help

  Example simple: bash $0 --bot-login BotLogin
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
    --db-login)         args="${args}-d " ;;
    --db-password)      args="${args}-c " ;;
    --prg-login)        args="${args}-l " ;;
    --checkout)         args="${args}-g " ;;
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
while getopts "b:s:k:p:d:c:l:g:x:w:t:fh" Option; do
  case ${Option} in
    b) bot_login=$OPTARG ;;        # Bot login
    d) db_login=$OPTARG ;;         # Login for DB
    c) db_password=$OPTARG ;;      # Password for DB
    l) prg_login=$OPTARG ;;        # Login for PRG
    g) checkout=$OPTARG ;;         # Checkout projects
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
set_default_value 'checkout' 'yes'
set_default_value 'host_trunk' 'wellnessliving.local'
set_default_value 'host_stable' 'stable.wellnessliving.local'
set_default_value 'host_production' 'production.wellnessliving.local'
set_default_value 'host_studio' 'studio.tr'

printf "Checking root permissions: "
if [[ "x$(id -u)" == 'x0' ]]; then
  check_result 1 "The script can not be run under the root"
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

printf "Checking set argument --workspace: "
if [[ ! -n "${workspace}" ]]; then
  check_result 1 "Workspace path not set or empty. Try 'bash $0 --help' for more information."
fi
echo "[OK]"

unix_workspace=$(echo "${workspace}" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\)\:/\(.*\)|/mnt/\L\1\E/\2|')

if [[ $(echo ${unix_workspace: -1}) == "/" ]]; then
  unix_workspace=${unix_workspace::-1}
fi

mkdir -p -v ${unix_workspace}
printf "Checking path workspace: "
if [[ -d "${unix_workspace}" ]]; then
  if [[ ! -z "$(ls -A ${unix_workspace})" ]]; then
    if [[ "$checkout" == "yes" ]]; then
      if [[ -z "$force" ]]; then
        echo -e "${Red} Directory ${unix_workspace} not empty. Please cleanup folder ${unix_workspace} ${NC} or use argument --force for automatic cleanup"
        exit 1
      fi
      echo -e "${Red}Force installing${NC}"
    fi
  fi
else
  check_result 1 "Path ${unix_workspace} not found."
  exit 1
fi
echo "[OK]"

echo "Checkout projects: ${checkout}"
echo "Workspace: ${unix_workspace}"
echo "Login for PRG: ${prg_login}"
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

if [[ ! -n "${a_site}" ]]; then
  check_result 1 "You must select at least one site."
fi

printf "Creating file structure: "

mkdir -p ${unix_workspace}/keys
mkdir -p ${unix_workspace}/less/4.1.3

for project in ${a_site}; do
  mkdir -p ${unix_workspace}/${project}/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
done

echo -e "${Purple}#----------------------------------------------------------#
#                    Configuring system                    #
#----------------------------------------------------------#${NC}"
status=""
while [ "$status" != "ok" ]; do
  read -p 'Write one time password from studio: ' one_time_password

  tmp_repository_file=$(mktemp -p /tmp)
  curl -s 'https://dev.1024.info/en-default/Studio/Personnel/Key.json' -X POST --data "s_login=${bot_login}&s_user_password=${one_time_password}&s_repository=libs" -o ${tmp_repository_file}

  status=`jq -M -r '.status' ${tmp_repository_file}`

  if [[ "$status" != 'ok' ]]; then
    message=`jq -M -r '.message' ${tmp_repository_file}`
    echo "Error getting repository key: ${message}"
    echo "Status: ${status}"
    echo ${tmp_repository_file}
    echo
    read -p 'Try again?[y/n]: ' answer
    if [[ "$answer" = 'n' ]] || [[ "$answer" = 'N'  ]]; then
      exit 1
    fi
  fi
done

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

if [[ $(echo ${unix_key: -1}) == "/" ]]; then
  unix_key=${unix_key::-1}
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
    chmod 600 ${unix_workspace}/keys/libs.key
    openssl rsa -in ${unix_workspace}/keys/libs.key -out ${unix_workspace}/keys/libs.pub -passin pass:${passphrase}
    check_result $? 'Decrypt key error'
    chmod 600 ${unix_workspace}/keys/libs.pub
  else
    check_result 1 "Passphrase for key not set. Try 'bash $0 --help' for more information."
  fi
else
  check_result 1 "Key not set."
fi

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

# Configuring svn on WSL
svn info
printf "Configuring SVN: "
sudo echo "[tunnels]" > /Users/${USER}/.subversion/config
sudo echo "libs = ssh svn@libs.svn.1024.info -p 35469 -i ${unix_workspace}/keys/libs.pub" >> /Users/${USER}/.subversion/config

mkdir -p ${unix_workspace}/install_tmp

echo "Checkouting templates files for configuring system"
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp

install_tmp=${unix_workspace}/install_tmp
# path to templates
templates=${install_tmp}/templates_mac

if [[ ! -d "$templates" ]]; then
  svn co svn+libs://libs.svn.1024.info/reservationspot.com/install ${unix_workspace}/install_tmp
  if [[ ! -d "$templates" ]]; then
    check_result 1 "Error while checkouting templates"
  fi
fi

git clone https://github.com/wellnessliving/wl-sdk.git ${unix_workspace}/wl-sdk
git clone https://github.com/wellnessliving/wl-docker.git ${unix_workspace}/wl-docker

cp -r ${unix_workspace}/wl-docker/* ${unix_workspace}/
rm -rf ${unix_workspace}/wl-docker

# Shared
svn co "svn+libs://libs.svn.1024.info/shared" "${unix_workspace}/shared"

# Trunk
svn co "svn+libs://libs.svn.1024.info/core/trunk" "${unix_workspace}/wl.trunk/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "${unix_workspace}/wl.trunk/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "${unix_workspace}/wl.trunk/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "${unix_workspace}/wl.trunk/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "${unix_workspace}/wl.trunk/project" # project
svn co "svn+libs://libs.svn.1024.info/Thoth/Report/trunk" "${unix_workspace}/wl.trunk/Thoth/Report" # Thoth Report
svn co "svn+libs://libs.svn.1024.info/Thoth/ReportCore/trunk" "${unix_workspace}/wl.trunk/Thoth/ReportCore" # Thoth ReportCore
svn co "svn+libs://libs.svn.1024.info/Thoth/WlShared/trunk" "${unix_workspace}/wl.trunk/Thoth/WlShared" # Thoth WlShared
svn co "svn+libs://libs.svn.1024.info/Thoth/PayProcessor/trunk" "${unix_workspace}/wl.trunk/Thoth/PayProcessor" # Thoth PayProcessor
svn co "svn+libs://libs.svn.1024.info/Thoth/DriveMs/trunk" "${unix_workspace}/wl.trunk/Thoth/DriveMs" # Thoth DriveMs

# Stable
svn co "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "${unix_workspace}/wl.stable/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "${unix_workspace}/wl.stable/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "${unix_workspace}/wl.stable/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "${unix_workspace}/wl.stable/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "${unix_workspace}/wl.stable/project" # project
svn co "svn+libs://libs.svn.1024.info/Thoth/Report/servers/stable" "${unix_workspace}/wl.stable/Thoth/Report" # Thoth Report
svn co "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/stable" "${unix_workspace}/wl.stable/Thoth/ReportCore" # Thoth ReportCore
svn co "svn+libs://libs.svn.1024.info/Thoth/WlShared/servers/stable" "${unix_workspace}/wl.stable/Thoth/WlShared" # Thoth WlShared
svn co "svn+libs://libs.svn.1024.info/Thoth/PayProcessor/servers/stable" "${unix_workspace}/wl.stable/Thoth/PayProcessor" # Thoth PayProcessor
svn co "svn+libs://libs.svn.1024.info/Thoth/DriveMs/servers/stable" "${unix_workspace}/wl.stable/Thoth/DriveMs" # Thoth DriveMs

# Stable Old
svn co "svn+libs://libs.svn.1024.info/core/servers/stable-old" "${unix_workspace}/wl.stable.old/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/stable-old" "${unix_workspace}/wl.stable.old/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/stable-old" "${unix_workspace}/wl.stable.old/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable-old" "${unix_workspace}/wl.stable.old/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable-old" "${unix_workspace}/wl.stable.old/project" # project
svn co "svn+libs://libs.svn.1024.info/Thoth/Report/servers/stable-old" "${unix_workspace}/wl.stable.old/Thoth/Report" # Thoth Report
svn co "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/stable-old" "${unix_workspace}/wl.stable.old/Thoth/ReportCore" # Thoth  ReportCore
svn co "svn+libs://libs.svn.1024.info/Thoth/WlShared/servers/stable-old" "${unix_workspace}/wl.stable.old/Thoth/WlShared" # Thoth  WlShared
svn co "svn+libs://libs.svn.1024.info/Thoth/PayProcessor/servers/stable-old" "${unix_workspace}/wl.stable.old/Thoth/PayProcessor" # Thoth PayProcessor
svn co "svn+libs://libs.svn.1024.info/Thoth/DriveMs/servers/stable-old" "${unix_workspace}/wl.stable.old/Thoth/DriveMs" # Thoth DriveMs

# Production
svn co "svn+libs://libs.svn.1024.info/core/servers/www.wellnessliving.com" "${unix_workspace}/wl.production/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-production" "${unix_workspace}/wl.production/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-production" "${unix_workspace}/wl.production/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/production" "${unix_workspace}/wl.production/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/production" "${unix_workspace}/wl.production/project" # project
svn co "svn+libs://libs.svn.1024.info/Thoth/Report/servers/production" "${unix_workspace}/wl.production/Thoth/Report" # Thoth Report
svn co "svn+libs://libs.svn.1024.info/Thoth/ReportCore/servers/production" "${unix_workspace}/wl.production/Thoth/ReportCore" # Thoth ReportCore
svn co "svn+libs://libs.svn.1024.info/Thoth/WlShared/servers/production" "${unix_workspace}/wl.production/Thoth/WlShared" # Thoth WlShared
svn co "svn+libs://libs.svn.1024.info/Thoth/PayProcessor/servers/production" "${unix_workspace}/wl.production/Thoth/PayProcessor" # Thoth PayProcessor
svn co "svn+libs://libs.svn.1024.info/Thoth/DriveMs/servers/production" "${unix_workspace}/wl.production/Thoth/DriveMs" # Thoth DriveMs

#s_geo_host=$(crudini --get ${install_tmp}/config/geo.ini connect host)
#s_geo_login=$(crudini --get ${install_tmp}/config/geo.ini connect login)
#s_geo_name=$(crudini --get ${install_tmp}/config/geo.ini connect name)
#s_geo_password=$(crudini --get ${install_tmp}/config/geo.ini connect password)
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

  path_config=${unix_workspace}/${project}/project/.config
  mkdir -p -v ${path_config}

  cp "${path_htprivate}/options/addr.php" "${path_htprivate}/options/addr.php.bak"

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
