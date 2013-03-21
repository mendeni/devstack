#!/bin/bash

cd /root

apt-get update
apt-get -y install git python-pip

git clone git://github.com/mendeni/devstack.git
pip install netaddr

cd devstack
cat<<EOF > localrc
ADMIN_PASSWORD=nomoresecrete
MYSQL_PASSWORD=stackdb
RABBIT_PASSWORD=stackqueue
SERVICE_PASSWORD=\$ADMIN_PASSWORD
SERVICE_TOKEN=letmein
EOF

./stack.sh

/usr/lib/rabbitmq/lib/rabbitmq_server-2.7.1/sbin/rabbitmq-plugins enable rabbitmq_management
/etc/init.d/rabbitmq-server restart
