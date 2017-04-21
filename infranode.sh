#!/bin/bash
# Last Modified : 2016-05-26

rhn_username=$1
rhn_pass=$2
rhn_pool=$3

sed -i -e 's/enabled.*/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
yum clean all 

subscription-manager register --username=${rhn_username} --password=${rhn_pass} --force
subscription-manager attach --pool=${rhn_pool}
subscription-manager repos --disable='*' \
  --enable='rhel-7-server-rpms' \
  --enable='rhel-7-server-extras-rpms' \
  --enable='rhel-7-server-ose-3.5-rpms' \
  --enable='rhel-7-fast-datapath-rpms'

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion
yum -y update
yum -y install atomic-openshift-utils
yum -y install atomic-openshift-excluder atomic-openshift-docker-excluder
atomic-openshift-excluder unexclude
yum -y docker

#sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker

cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/sdc
VG=docker-vg
EOF

docker-storage-setup
systemctl enable docker
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl restart docker

setsebool -P virt_sandbox_use_nfs 1
setsebool -P virt_use_nfs 1
