#!/bin/bash
# © Petro Ostapuk, Oct 2019, petroostapuk@gmail.com
# A script for installing MySQL Database for trunk on Ubuntu.
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
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
White='\033[0;37m'        # White

# Defining function to set default value
set_default_value() {
  eval variable=\$$1
  if [[ -z "$variable" ]]; then
    eval $1=$2
  fi
}

#Seting default value for arguments
set_default_value 'db_login' 'koins'
set_default_value 'db_password' 'lkchpy91'
set_default_value 'checkout' 'yes'
set_default_value 'host_trunk' 'wellnessliving.local'

printf "${Green}Checking root permissions: ${NC}"
if [[ "x$(id -u)" != 'x0' ]]; then
  check_result 1 "${Green}Script can be run executed only by root"
fi
echo -e "${Yellow}[OK]${NC}"

printf "${Green}Checking set argument --db-login: ${NC}"
if [[ ! -n "${db_login}" ]]; then
  check_result 1 "DB login not set or empty. Try 'bash $0 --help' for more information."
fi
if [[ "${db_login}" == "root" ]]; then
  check_result 1 "DB login must not be root. Try 'bash $0 --help' for more information."
fi
echo -e "${Yellow}[OK]${NC}"

printf "${Green}Checking set argument --db-password: ${NC}"
if [[ ! -n "${db_password}" ]]; then
  check_result 1 "DB password not set or empty. Try 'bash $0 --help' for more information."
fi
echo -e "${Yellow}[OK]${NC}"

echo -e "Login for DB: ${Blue}${db_login}${NC}"
echo -e "Password for DB: ${Blue}${db_password}${NC}"
echo -e "Host for trunk: ${Blue}${host_trunk}${NC}"

# Asking for confirmation to proceed
read -p "Would you like to continue [y/n]: " answer
if [[ "$answer" != 'y' ]] && [[ "$answer" != 'Y'  ]]; then
  echo -e "${Yellow}Goodbye{NC}${White}"
  exit 1
fi

a_site=""

#Folders for production
if [[ ! -z "$host_trunk" ]]; then
  a_site+=" wl.trunk"
fi

if [[ ! -n "${a_site}" ]]; then
  check_result 1 "You must select at least one site."
fi

#set password for mysql user root
mysqladmin -u root password ${db_password}

#Create new DB user
  mysql -uroot -p${db_password} -e "create user '${db_login}'@'localhost' identified BY '${db_password}';"

  a_privileges="alter,create,delete,drop,index,insert,lock tables,references,select,update,trigger"

  mysql -uroot -p${db_password} -e "create database a_geo;"
  mysql -uroot -p${db_password} -e "grant ${a_privileges} on a_geo.* to '${db_login}'@'localhost';"

echo -e "${Yellow}===============================================================================${NC}"
echo -e "${Blue}Start creating databases!${NC}"
echo -e "${Yellow}===============================================================================${NC}"
  #Creating databases
  for project in ${a_site}; do
    project=$(echo "$project" | sed -r 's/\./_/g')
    for db_name in main control test_main test_geo; do
      mysql -uroot -p${db_password} -e "drop database ${project}_${db_name};"
      mysql -uroot -p${db_password} -e "create database ${project}_${db_name};"
      mysql -uroot -p${db_password} -e "grant ${a_privileges} on ${project}_${db_name}.* to '${db_login}'@'localhost';"
    done
  done
  mysql -uroot -p${db_password} -e "flush privileges;"
echo -e "${Yellow}===============================================================================${NC}"
