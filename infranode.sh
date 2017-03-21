#!/bin/bash

# Install a NFS server on infranode
sudo su -
yum install nfs-utils rpcbind
systemctl enable nfs-server
systemctl enable rpcbind
systemctl start nfs-server

# Create exports directory for hosting Persistent Volumes
mkdir /exports
cd /exports

# Create a bunch of directories for later PV
n=1
while [ $n -le 9 ]
  do mkdir pv000$n
  chown -R nfsnobody:nfsnobody pv000$n/
  chmod -R 777 pv000$n
  (( n++ ))
done

n=10
while [ $n -le 20 ]
  do mkdir pv00$n
  chown -R nfsnobody:nfsnobody pv00$n/
  chmod -R 777 pv00$n
  (( n++ ))
done

CAT <<EOF > /etc/exports.d/openshif-ansible
/exports/pv0001 *(rw,root_squash)
/exports/pv0002 *(rw,root_squash)
/exports/pv0003 *(rw,root_squash)
/exports/pv0004 *(rw,root_squash)
/exports/pv0005 *(rw,root_squash)
/exports/pv0006 *(rw,root_squash)
/exports/pv0007 *(rw,root_squash)
/exports/pv0008 *(rw,root_squash)
/exports/pv0009 *(rw,root_squash)
/exports/pv0010 *(rw,root_squash)
/exports/pv0011 *(rw,root_squash)
/exports/pv0012 *(rw,root_squash)
/exports/pv0013 *(rw,root_squash)
/exports/pv0014 *(rw,root_squash)
/exports/pv0015 *(rw,root_squash)
/exports/pv0016 *(rw,root_squash)
/exports/pv0017 *(rw,root_squash)
/exports/pv0018 *(rw,root_squash)
/exports/pv0019 *(rw,root_squash)
/exports/pv0020 *(rw,root_squash)
EOF

# Exports everything and force refresh of iptables
exportfs -r
iptables -F
