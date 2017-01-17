#!/bin/bash
# Last Modified : 2016-08-29

USERNAME=$1
PASSWORD=$2
HOSTNAME=$3
NODECOUNT=$4
ROUTEREXTIP=$5
rhn_username=$6
rhn_pass=$7
rhn_pool=$8


subscription-manager register --username=${rhn_username} --password=${rhn_pass} --force
subscription-manager attach --pool=${rhn_pool}

subscription-manager repos --disable='*'
subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.2-rpms"

sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rh-cloud.repo
sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rhui-load-balancers

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker
yum -y install atomic-openshift-utils
# yum -y update

sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker

cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/sdc
VG=docker-vg
EOF

docker-storage-setup
systemctl enable docker
systemctl start docker


cat <<EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=${USERNAME}
ansible_become=true
debug_level=2
deployment_type=openshift-enterprise

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_default_subdomain=${ROUTEREXTIP}.xip.io
openshift_use_dnsmasq=False

openshift_registry_selector="role=infra"
openshift_router_selector="role=infra"


# Install the openshift examples
openshift_install_examples=true

# Enable cluster metrics
use_cluster_metrics=true

# Configure metricsPublicURL in the master config for cluster metrics
openshift_master_metrics_public_url=https://${HOSTNAME}/hawkular/metrics

# Configure loggingPublicURL in the master config for aggregate logging
openshift_master_logging_public_url=https://kibana.${HOSTNAME}

# Defining htpasswd users (password is redhat123)
openshift_master_htpasswd_users={'admin': '\$apr1\$bdqbl2eo\$Na6mZ6SG7Vfo3YPyp1vJP.', 'demo': '\$apr1\$ouJ9QtwY\$Z2WZ9yvm1.tNzipdR.4Wp1'}

# Enable cockpit
osm_use_cockpit=true
osm_cockpit_plugins=['cockpit-kubernetes']

openshift_router_selector='region=infra'
openshift_registry_selector='region=infra'


# Configure an internal regitry / NOT YET SUPPORTED
# openshift_hosted_registry_storage_kind=nfs
# openshift_hosted_registry_storage_host=infranode
# openshift_hosted_registry_storage_nfs_directory=/exports
# openshift_hosted_registry_storage_volume_name=registry
# openshift_hosted_registry_storage_volume_size=5Gi

[masters]
master openshift_node_labels="{'region': 'infra', 'zone': 'default'}"  openshift_public_hostname=${HOSTNAME}


[nodes]
master
node[01:${NODECOUNT}] openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
infranode openshift_node_labels="{'region': 'infra', 'zone': 'default'}"

EOF

cat <<EOF > /home/${USERNAME}/openshift-install.sh
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
EOF

chmod 755 /home/${USERNAME}/openshift-install.sh
