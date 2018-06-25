# Installing project for WSL Ubuntu 16.04

This installer does the following:
* Install packages:
  * mc 
  * mcedit 
  * apache2 
  * mysql-server 
  * php7.1 
  * php7.1-bcmath 
  * php7.1-xml 
  * php7.1-curl 
  * php7.1-gd 
  * php7.1-mbstring 
  * php7.1-mcrypt 
  * php7.1-mysql 
  * php7.1-soap 
  * php7.1-tidy 
  * php7.1-zip 
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
```
.
├── checkout
│   ├── core
│   │   ├── servers
│   │   │   └── stable.wellnessliving.com
│   │   └── trunk
│   ├── dev.1024.info
│   │   └── trunk
│   ├── namespace
│   │   ├── Core
│   │   │   ├── servers
│   │   │   │   └── wl-stable
│   │   │   └── trunk
│   │   ├── Social
│   │   │   ├── servers
│   │   │   │   ├── wl-production
│   │   │   │   └── wl-stable
│   │   │   └── trunk
│   │   ├── Studio
│   │   │   └── trunk
│   │   └── Wl
│   │       ├── servers
│   │       │   └── stable
│   │       └── trunk
│   ├── reservationspot.com
│   │   ├── install
│   │   ├── servers
│   │   │   └── stable
│   │   └── trunk
│   └── shared
├── .htprivate
│   ├── wl.st
│   │   ├── options
│   │   │   └── a
│   │   └── writable
│   │       ├── app
│   │       ├── cache
│   │       │   ├── persistent
│   │       │   └── system
│   │       ├── debug
│   │       ├── log
│   │       ├── php
│   │       ├── sql
│   │       ├── templates
│   │       │   ├── app
│   │       │   ├── clean
│   │       │   ├── combat
│   │       │   ├── combatframe
│   │       │   ├── default
│   │       │   ├── fight
│   │       │   ├── fightframe
│   │       │   ├── frame
│   │       │   ├── metabody
│   │       │   ├── metabodyframe
│   │       │   ├── print
│   │       │   ├── spa
│   │       │   ├── staff
│   │       │   ├── system
│   │       │   ├── wellnessliving
│   │       │   ├── wellnesslivingframe
│   │       │   ├── yfpassport
│   │       │   └── yfpassportframe
│   │       ├── tmp
│   │       └── var
│   │           └── selenium
│   └── wl.tr
│       ├── options
│       │   └── a
│       └── writable
│           ├── app
│           ├── cache
│           │   ├── persistent
│           │   └── system
│           ├── debug
│           ├── log
│           ├── php
│           ├── sql
│           ├── templates
│           │   ├── app
│           │   ├── clean
│           │   ├── combat
│           │   ├── combatframe
│           │   ├── default
│           │   ├── fight
│           │   ├── fightframe
│           │   ├── frame
│           │   ├── metabody
│           │   ├── metabodyframe
│           │   ├── print
│           │   ├── spa
│           │   ├── staff
│           │   ├── system
│           │   ├── wellnessliving
│           │   ├── wellnesslivingframe
│           │   ├── yfpassport
│           │   └── yfpassportframe
│           ├── tmp
│           └── var
│               └── selenium
├── keys
├── public_html
│   ├── a
│   │   ├── drive
│   │   └── img
│   ├── debug
│   │   └── img
│   ├── im
│   ├── prg
│   │   └── img
│   ├── rs
│   ├── static
│   └── xmlfilter
├── selenium
├── wl.stable
│   ├── core -> ../checkout/core/servers/stable.wellnessliving.com
│   ├── namespace.Core -> ../checkout/namespace/Core/servers/wl-stable
│   ├── namespace.Social -> ../checkout/namespace/Social/servers/wl-stable
│   ├── namespace.Wl -> ../checkout/namespace/Wl/servers/stable
│   └── project -> ../checkout/reservationspot.com/servers/stable
└── wl.trunk
    ├── core -> /mnt/d/Workspace/checkout/core/trunk
    ├── namespace.Core -> /mnt/d/Workspace/checkout/namespace/Core/trunk
    ├── namespace.Social -> /mnt/d/Workspace/checkout/namespace/Social/trunk
    ├── namespace.Wl -> ../checkout/namespace/Wl/trunk
    └── project -> /mnt/d/Workspace/checkout/reservationspot.com/trunk
```
* Checkouting project
* Creating database
* Setup project
* Install on Windows:
  * Putty 0.70
  * Subversion 1.7.9
