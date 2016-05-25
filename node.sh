#!/bin/bash
echo toto >> /root/toto
#rhn_username=$1
#rhn_pass=$2
#rhn_pool=$3
#
#touch /root/mylogs
#echo $date >> /root/mylogs
#
#subscription-manager register --username="$rhn_username" --password="$rhn_password" --pool="$rhn_pool"
#echo $? >> /root/mylogs
#subscription-manager repos --disable="*"
#subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.2-rpms"
#
#
#yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker
#
#sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker
#
#cat <<EOF > /etc/sysconfig/docker-storage-setup
#DEVS=/dev/sdc
#VG=docker-vg
#EOF
#
#docker-storage-setup
#systemctl enable docker
