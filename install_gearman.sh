#!/bin/bash

if test "$BASH" = ""; then
  check_result 1 "You must use: bash $0"
fi

apt update

apt -y install gearman php-gearman
service apache2 restart
service gearman-job-serve start
