#!/bin/bash

BS=/vagrant/vagrant-bootstrap
CONFIG=/vagrant/configuration.yaml

if [ ! -f $CONFIG ]
then
  echo "Please provide a configuration.yaml file in the project directory - use configuration.yaml.example as a starting point"
  echo "After configuration.yaml is in place, please run 'vagrant provision'"
  exit 5
fi

NODE_COUNT=${1:-1}
OS=${2:-centos}
MINION_ID=${3}
HOSTNAME=$(echo $MINION_ID|cut -d '.' -f 1)

cp -v ${BS}/minion /etc/salt/minion
echo ${MINION_ID} > /etc/salt/minion_id

#lokkit -p 22:tcp -p 4505:tcp -p 4506:tcp
if [ $OS == centos ]
then
  service iptables stop
  chkconfig iptables off
fi

if [ $NODE_COUNT -gt 0 ]
then
  if [ $HOSTNAME == namenode ]
  then
    cp ${BS}/grains.namenode /etc/salt/grains
  else
    cp ${BS}/grains.datanode /etc/salt/grains
  fi
else
  cp ${BS}/grains.standalone /etc/salt/grains
fi

echo "# attached configuration.yaml" >> /etc/salt/grains
cat $CONFIG >> /etc/salt/grains

service salt-minion restart

if [ $HOSTNAME == namenode ]
then
  cachedir=/var/cache/salt/master/gitfs
  [ ! -d $cachedir ] && mkdir -p $cachedir
  cp -v ${BS}/master /etc/salt/master
  if [ ! -f /srv/salt/hadoop/files/dsa-hdfs.pub ]
  then
    cd /srv/salt/tools && ./generate_all.sh
  fi
  service salt-master restart
  echo "===> waiting for minion key requests ..."
  sleep 10
  echo
  salt-key -y -A
fi
