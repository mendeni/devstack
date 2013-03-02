#!/bin/bash

sudo apt-get install python-pip python-dev git gcc

sudo pip install eventlet

git clone git://github.com/openstack/python-novaclient.git
# git pull # (if you need to update)
cd python-novaclient
sudo python setup.py install

git clone git://github.com/rackerhacker/supernova.git
# git pull # (if you need to update)
cd supernova
sudo python setup.py install

cat<<EOF > ~/.supernova
[dev]
OS_AUTH_URL=http://127.0.0.1:5000/v2.0/
NOVACLIENT_INSECURE=1
NOVA_VERSION="1.1"
OS_TENANT_NAME=demo
OS_USERNAME=demo
OS_PASSWORD=nomoresecrete
OS_REGION_NAME=RegionOne
EOF

supernova dev flavor-list
supernova dev image-list
# supernova dev boot --image beb9cb53-4826-484a-a433-58e7e0cf81f9 --flavor 42 test$$
