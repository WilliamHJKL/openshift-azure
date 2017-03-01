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

subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.4-rpms"

sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rh-cloud.repo
sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rhui-load-balancers

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker
yum -y install atomic-openshift-utils
yum -y update

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
nfs

[OSEv3:vars]
ansible_ssh_user=${USERNAME}
ansible_become=true
debug_level=2
deployment_type=openshift-enterprise

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_default_subdomain=${ROUTEREXTIP}.xip.io
openshift_use_dnsmasq=False

# Install the openshift examples
openshift_install_examples=true

# Enable cluster metrics
use_cluster_metrics=true

# Configure metricsPublicURL in the master config for cluster metrics
openshift_master_metrics_public_url=https://metrics.${ROUTEREXTIP}.xip.io/hawkular/metrics

# Configure loggingPublicURL in the master config for aggregate logging
openshift_master_logging_public_url=https://kibana.${ROUTEREXTIP}.xip.io

# Defining htpasswd users (password is redhat123)
openshift_master_htpasswd_users={'admin': '\$apr1\$bdqbl2eo\$Na6mZ6SG7Vfo3YPyp1vJP.', 'demo': '\$apr1\$ouJ9QtwY\$Z2WZ9yvm1.tNzipdR.4Wp1'}

# Enable cockpit
osm_use_cockpit=true
osm_cockpit_plugins=['cockpit-kubernetes']

# default project node selector
osm_default_node_selector='region=primary'

openshift_router_selector='region=infra'
openshift_registry_selector='region=infra'

# Configure an internal regitry
openshift_hosted_registry_selector=‘region=infra'
openshift_hosted_registry_replicas=1
openshift_hosted_registry_storage_kind=nfs
openshift_hosted_registry_storage_access_modes=['ReadWriteMany']
openshift_hosted_registry_storage_host=infranoce
openshift_hosted_registry_storage_nfs_directory=/exports
openshift_hosted_registry_storage_volume_name=registry
openshift_hosted_registry_storage_volume_size=5Gi

# Enable metrics
openshift_hosted_metrics_deploy=true
openshift_hosted_metrics_storage_kind=nfs
openshift_hosted_metrics_storage_access_modes=['ReadWriteOnce']
openshift_hosted_metrics_storage_host=oselab.example.com
openshift_hosted_metrics_storage_nfs_directory=/exports
openshift_hosted_metrics_storage_volume_name=metrics
openshift_hosted_metrics_storage_volume_size=5Gi

[nfs]
infranode

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

n=1
while [ $n -le 9 ]
do
cat <<EOF > /home/${USERNAME}/pv000$n.json
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "pv000$n"
  },
  "spec": {
    "capacity": {
        "storage": "1Gi"
    },
    "accessModes": [ "ReadWriteOnce", "ReadWriteMany" ],
    "nfs": {
        "path": "/exports/pv000$n",
        "server": "infranode"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
(( n++ ))
done

n=10
while [ $n -le 15 ]
do
cat <<EOF > /home/${USERNAME}/pv00$n.json
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "pv00$n"
  },
  "spec": {
    "capacity": {
        "storage": "5Gi"
    },
    "accessModes": [ "ReadWriteOnce", "ReadWriteMany" ],
    "nfs": {
        "path": "/exports/pv00$n",
        "server": "infranode"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
(( n++ ))
done

n=16
while [ $n -le 20 ]
do
cat <<EOF > /home/${USERNAME}/pv00$n.json
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "pv00$n"
  },
  "spec": {
    "capacity": {
        "storage": "25Gi"
    },
    "accessModes": [ "ReadWriteOnce", "ReadWriteMany" ],
    "nfs": {
        "path": "/exports/pv00$n",
        "server": "infranode"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
(( n++ ))
done

cat <<EOF > /home/${USERNAME}/create-pvs.sh
n=1
while [ \$n -le 9 ]
do
  oc create -f pv000\$n.json
  (( n++ ))
done
n=10
while [ \$n -le 20 ]
do
oc create -f pv00\$n.json
(( n++ ))
done
EOF

chmod 755 /home/${USERNAME}/create-pvs.sh

cat <<EOF > /home/${USERNAME}/openshift-services-deploy.sh

oc project openshift-infra
oc annotate namespace openshift-infra openshift.io/node-selector='region=infra' --overwrite
oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster
oc adm policy add-role-to-user view system:serviceaccount:openshift-infra:hawkular -n openshift-infra

oc process metrics-deployer-template -n openshift \
  -v HAWKULAR_METRICS_HOSTNAME=metrics.${ROUTEREXTIP}.xip.io \
  -v IMAGE_VERSION=v3.4 -v IMAGE_PREFIX=registry.access.redhat.com/openshift3/ \
  -v USE_PERSISTENT_STORAGE=true \
  -v CASSANDRA_PV_SIZE=5Gi \
  | oc create -f -

oc project logging
oc new-app logging-deployer-account-template
oadm policy add-cluster-role-to-user oauth-editor system:serviceaccount:logging:logging-deployer
oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:logging:aggregated-logging-fluentd
oadm policy add-cluster-role-to-user rolebinding-reader system:serviceaccount:logging:aggregated-logging-elasticsearch

oc process logging-deployer-template -n openshift \
  -v KIBANA_HOSTNAME=kibana.${ROUTEREXTIP}.xip.io \
  -v ES_CLUSTER_SIZE=1 \
  -v ES_INSTANCE_RAM=2G \
  -v ES_PVC_SIZE=5G \
  -v ES_NODESELECTOR='region=infra' \
  -v KIBANA_NODESELECTOR='region=infra' \
  -v CURATOR_NODESELECTOR='region=infra' \
  -v PUBLIC_MASTER_URL=https://${HOSTNAME}:8443 \
  -v ENABLE_OPS_CLUSTER=false \
  -v IMAGE_VERSION=v3.4 \
  -v IMAGE_PREFIX=registry.access.redhat.com/openshift3/ \
  | oc create -f -

n=1
while [ \$n -le $NODECOUNT ]
do
  oc label node/node0$n logging-infra-fluentd=true
  (( n++ ))
done
EOF
