#!/bin/bash

if test "$BASH" = ""; then
  echo "You must use: bash $0"
  exit 1
fi

apt update

apt -y install gearman php-gearman
service apache2 restart
service gearman-job-server start
