#!/bin/bash

apt-get -y install make libapache2-mod-wsgi

cd /root

. devstack/localrc

mysql -p$MYSQL_PASSWORD<<EOF
create database stacktach;
EOF

pip install Django
pip install MySQL-python
pip install eventlet
pip install kombu==2.4.7
pip install librabbitmq==1.0.0
pip install pympler

mkdir -vp /srv/www/stacktach/
mkdir -vp /srv/www/stacktach/apache
mkdir -vp /srv/www/stacktach/static
mkdir -vp /srv/www/stacktach/django/stproject/
mkdir -vp /srv/www/stacktach/wsgi/
mkdir -vp /srv/www/stacktach/htdocs

cd /srv/www/stacktach/django/stproject/ && git clone git://github.com/rackerlabs/stacktach.git .

ln -s /srv/www/stacktach/django/stproject/static/jquery.timers.js \
      /srv/www/stacktach/static/jquery.timers.js

ln -s /srv/www/stacktach/django/stproject \
      /srv/www/stacktach/app

ln -s /srv/www/stacktach/django/stproject \
      /stacktack

cat<<EOF > etc/stacktach_config.sh
export STACKTACH_DB_NAME="stacktach"
export STACKTACH_DB_HOST=""
export STACKTACH_DB_USERNAME="root"
export STACKTACH_DB_PASSWORD="$MYSQL_PASSWORD"
export STACKTACH_INSTALL_DIR="/srv/www/stacktach/django/stproject/"
export STACKTACH_DEPLOYMENTS_FILE="/srv/www/stacktach/django/stproject/etc/stacktach_worker_config.json"
export DJANGO_SETTINGS_MODULE="settings"
export STACKTACH_DB_ENGINE="django.db.backends.mysql"
EOF

cat<<EOF > local_settings.py
STACKTACH_DB_ENGINE="django.db.backends.mysql"
STACKTACH_DB_NAME="stacktach"
STACKTACH_DB_HOST=""
STACKTACH_DB_USERNAME="root"
STACKTACH_DB_PASSWORD="$MYSQL_PASSWORD"
STACKTACH_INSTALL_DIR="/srv/www/stacktach/django/stproject/"
STACKTACH_DEPLOYMENTS_FILE="/srv/www/stacktach/django/stproject/etc/stacktach_worker_config.json"
DJANGO_SETTINGS_MODULE="settings"
EOF


cat<<EOF > /srv/www/stacktach/django/stproject/etc/stacktach_worker_config.json
{"deployments": [
    {   
        "name": "dev",
        "durable_queue": false,
        "rabbit_host": "127.0.0.1",
        "rabbit_port": 5672,
        "rabbit_userid": "guest",
        "rabbit_password": "$RABBIT_PASSWORD",
        "rabbit_virtual_host": "/"
    }]
}
EOF

. etc/stacktach_config.sh

python manage.py syncdb

cat<<EOF > /srv/www/stacktach/wsgi/django.wsgi
import os
import sys

path = '/srv/www/stacktach/app/'
if path not in sys.path:
    sys.path.append(path)

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'

import django.core.handlers.wsgi
application = django.core.handlers.wsgi.WSGIHandler()
EOF

cat<<EOF > /etc/apache2/sites-available/stacktach
NameVirtualHost *:81
Listen 81

<VirtualHost *:81>
        ServerName localhost
        DocumentRoot /srv/www/stacktach/htdocs

        <Directory /srv/www/stacktach/htdocs>
                Order allow,deny
                Allow from all
        </Directory>

        <Directory /srv/www/stacktach/wsgi>
                Order allow,deny
                Allow from all
        </Directory>

        Alias /static/ /srv/www/stacktach/app/static/

        WSGIScriptAlias / /srv/www/stacktach/wsgi/django.wsgi
</VirtualHost>
EOF

ln -s /etc/apache2/sites-available/stacktach \
      /etc/apache2/sites-enabled/stacktach

service apache2 restart

/stacktack/worker/stacktach.sh start
