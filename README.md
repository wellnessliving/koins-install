# Installing project for WSL Ubuntu 18.04

This installer does the following:
* Install packages:
  * apache2
  * mysql-server
  * php7.2
  * php7.2-bcmath
  * php7.2-xml
  * php7.2-curl
  * php7.2-gd
  * php7.2-mbstring
  * php7.2-mysql
  * php7.2-soap
  * php7.2-tidy
  * php7.2-zip
  * php-apcu
  * php-memcached
  * memcached
  * phpmyadmin
  * crudini
  * libneon27-gnutls
  * dialog
  * putty-tools
  * libserf-1-1
  * subversion
* Setup packages.
* Creating folders structure.
* Checkouting project
* Creating database
* Setup project
* Install on Windows:
  * Putty 0.70
  * Subversion 1.7.9

# Project installer for Debian-based Linux distributions (no Windows involved)

**DO NOT** run this script as root. Run it under **your** normal user account. For actions evolving system configuration, `sudo` will be used, so ensure that you are in `sudoers` list and don't be surprised when the script asks for your password to activate `sudo`.
Be sure to get the proper configuration keys using https://output.jsbin.com/feguzef before running the script.

*Expect **a lot** of output. You could consider adding `2>&1 | tee SomeFile.log` to log the errors and output to a file to review it later*

The script will download (use and then delete) a number of files (e.g. keys, distribution files etc.) to the current directory. Ensure you have `write` rights to the folder you are running the script in.

Installation script does the following:
* Does full system update (apt update && upgrade)
* Installs packages needed for the project to run:
  * crudini
  * mysql-server-8.0.x
  * git
  * aptitude
  * apache2
  * php8.0 *(by adding ppa:ondrej/php)*
  * php8.0-dev
  * php-pear 
    * pecl sync
    * pecl inotify
  * php8.0-bcmath
  * php8.0-xml
  * php8.0-curl
  * php8.0-gd
  * php8.0-mbstring
  * php8.0-mysql
  * php8.0-soap
  * php8.0-tidy
  * php8.0-zip
  * php8.0-apcu
  * php8.0-memcached
  * memcached
  * libneon27-gnutls
  * libserf-1-1
  * jq
  * subversion
  * npm
  * nodejs
  * libaio1
  * libaio-dev
  * gearman
  * php8.0-gearman
* Creates project folder structure
* Configures packages
* Checks out project files form the repos
* Downloads latest selenium-server.jar and chromeDriver
* Creates the databases and runs migrations on them
* Sets up the project configuration

