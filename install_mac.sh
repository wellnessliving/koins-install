#!/bin/bash

mkdir -p /Users/olbo/Workspace/wl.trunk/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
mkdir -p /Users/olbo/Workspace/wl.stable/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
mkdir -p /Users/olbo/Workspace/wl.stable.old/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}
mkdir -p /Users/olbo/Workspace/wl.production/{.htprivate/{options,writable/{cache,debug,log,php,sql,tmp,var/selenium}},public_html/{a/drive,static}}

# Shared
svn co "svn+libs://libs.svn.1024.info/shared" "/Users/olbo/Workspace/shared"

# Trunk
svn co "svn+libs://libs.svn.1024.info/core/trunk" "/Users/olbo/Workspace/wl.trunk/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/trunk" "/Users/olbo/Workspace/wl.trunk/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/trunk" "/Users/olbo/Workspace/wl.trunk/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/trunk" "/Users/olbo/Workspace/wl.trunk/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/trunk" "/Users/olbo/Workspace/wl.trunk/project" # project

# Stable
svn co "svn+libs://libs.svn.1024.info/core/servers/stable.wellnessliving.com" "/Users/olbo/Workspace/wl.stable/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-stable" "/Users/olbo/Workspace/wl.stable/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-stable" "/Users/olbo/Workspace/wl.stable/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable" "/Users/olbo/Workspace/wl.stable/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable" "/Users/olbo/Workspace/wl.stable/project" # project

# Stable Old
svn co "svn+libs://libs.svn.1024.info/core/servers/stable-old" "/Users/olbo/Workspace/wl.stable.old/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/stable-old" "/Users/olbo/Workspace/wl.stable.old/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/stable-old" "/Users/olbo/Workspace/wl.stable.old/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/stable-old" "/Users/olbo/Workspace/wl.stable.old/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/stable-old" "/Users/olbo/Workspace/wl.stable.old/project" # project

# Production
svn co "svn+libs://libs.svn.1024.info/core/servers/www.wellnessliving.com" "/Users/olbo/Workspace/wl.production/core" # Core
svn co "svn+libs://libs.svn.1024.info/namespace/Core/servers/wl-production" "/Users/olbo/Workspace/wl.production/namespace.Core" # namespace.Core
svn co "svn+libs://libs.svn.1024.info/namespace/Social/servers/wl-production" "/Users/olbo/Workspace/wl.production/namespace.Social" # namespace.Social
svn co "svn+libs://libs.svn.1024.info/namespace/Wl/servers/production" "/Users/olbo/Workspace/wl.production/namespace.Wl" # namespace.Wl
svn co "svn+libs://libs.svn.1024.info/reservationspot.com/servers/production" "/Users/olbo/Workspace/wl.production/project" # project

db_login="koins"
db_password="lkchpy91"
a_site="wl.trunk wl.stable wl.production"
host_trunk="wl.trunk"
host_stable="wl.stable"
host_production="wl.production"
email="[email]"
bot_login="[login]"
bot_password="[robot_password]"
prg_login="admin"
s_geo_host=""

s_geo_host="geo-dev.czv5nwocnwdl.us-east-1.rds.amazonaws.com"
s_geo_login="u_dev"
s_geo_name="geo"
s_geo_password="7DHvCLwcDcNQGrq3"

mkdir -p /Users/olbo/Workspace/install_tmp

echo "Checkouting templates files for configuring system"
svn co svn+libs://libs.svn.1024.info/reservationspot.com/install /Users/olbo/Workspace/install_tmp

install_tmp=/Users/olbo/Workspace/install_tmp
# path to templates
templates=${install_tmp}/templates_mac

if [[ ! -d "$templates" ]]; then
  svn co svn+libs://libs.svn.1024.info/reservationspot.com/install /Users/olbo/Workspace/install_tmp
  if [[ ! -d "$templates" ]]; then
    check_result 1 "Error while checkouting templates"
  fi
fi

git clone https://github.com/wellnessliving/wl-sdk.git /Users/olbo/Workspace/wl-sdk

for project in ${a_site}; do
  path_htprivate="/Users/olbo/Workspace/${project}/.htprivate"

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
  cp ${templates}/public_html/index.php "/Users/olbo/Workspace/${project}/public_html/index.php"

  # public_html/.htaccess
  sed -e "
  s;%workspace%;/Users/olbo/Workspace;g
  s;%project%;${project};g
  " ${templates}/public_html/.htaccess > "/Users/olbo/Workspace/${project}/public_html/.htaccess"

  # public_html/favicon.ico
  cp ${templates}/public_html/favicon.ico "/Users/olbo/Workspace/${project}/public_html/favicon.ico"

  cp ${s_options_template} /Users/olbo/Workspace/${project}/.htprivate/options/options.php
  cp ${templates}/options/inc.php /Users/olbo/Workspace/${project}/.htprivate/options/inc.php
  cp ${templates}/options/cli.php /Users/olbo/Workspace/${project}/.htprivate/options/cli.php

  path_config=/Users/olbo/Workspace/${project}/project/.config
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

chmod 777 -R /Users/olbo/Workspace

exit 0
