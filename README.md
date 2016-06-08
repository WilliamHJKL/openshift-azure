This work is based on https://github.com/derdanu

# RedHat Openshift 3.2 cluster on Azure

When creating the RedHat Openshift 3.2 cluster on Azure, you will need a SSH RSA key for access.

## Create the cluster

To have OpenShift Enterprise 3.2 running on Azure, you will have to
follow 2 steps.
- First deploy the cluster with one of the following method.
- Then use ansible to install OSE 3.2 ( in a word run the
openshift-install.sh script.

### Create the cluster on the Azure Portal

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWilliamRedHat%2Fopenshift-azure%2Frhel%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FWilliamRedHat%2Fopenshift-azure%2Frhel%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

### Create the cluster with powershell

```powershell
New-AzureRmResourceGroupDeployment -Name <DeploymentName> -ResourceGroupName <RessourceGroupName> -TemplateUri https://raw.githubusercontent.com/WilliamRedHat/openshift-azure/rhel/azuredeploy.json
```
### Create the cluster with Azure CLI on RHEL 7.2

#### Install Azure CLI
Use the knowledge base article : https://access.redhat.com/articles/1994463

#### Use the Azure CLI
```

[hoffmann@william ~]$ git clone https://github.com/WilliamRedHat/openshift-azure.git
[hoffmann@william ~]$ cd ~/openshift-azure/
```

Update the azuredeploy.parameters.json file with your parameters

Create a resource group :

```
  [hoffmann@william ~]$ azure config mode arm
  [hoffmann@william ~]$ azure location list
  [hoffmann@william ~]$ azure group create -n "RG-OSE32" -l "West US"
  [hoffmann@william ~]$ azure group deployment create -f azuredeploy.json -e azuredeploy.parameters.json RG-OSE32 dnsName

```
Note the output :

```
  data:    Outputs            :
  data:    Name                        Type    Value                                       
  data:    --------------------------  ------  --------------------------------------------
  data:    openshift Webconsole        String  https://ose32.westus.cloudapp.azure.com:8443
  data:    openshift Master ssh        String  ssh -A 13.91.51.205                         
  data:    openshift Router Public IP  String  13.91.101.166                               
  info:    group deployment create command OK

```
You're now able to go to the next step.

## Install Openshift with Ansible

You must use SSH Agentforwarding.
You must register your systems into RHN and to add the proper channels.

```
[adminUsername@master ~]$ ./openshift-install.sh
```

## Configure NFS storage
FIXME : add pv / pvc
```
[adminUsername@infranode ~]$ sudo su -
[adminUsername@infranode ~]$ yum install nfs-utils  rpcbind
[adminUsername@infranode ~]$ systemctl enable nfs-server
[adminUsername@infranode ~]$ systemctl enable rpcbind
[adminUsername@infranode ~]$ mkdir /exports
[adminUsername@infranode ~]$ vim /etc/exports
[adminUsername@infranode ~]$ systemctl start nfs-server
[adminUsername@infranode ~]$ exportfs -r
```

------

## Parameters
### Input Parameters

```
| Name          | Type          | Description                                      |   |
| ------------- | ------------- | -------------                                    |   |
| adminUsername | String        | Username for SSH Login and Openshift Webconsole  |   |
| adminPassword | SecureString  | Password for the Openshift Webconsole            |   |
| sshKeyData    | String        | Public SSH Key for the Virtual Machines          |   |
| masterDnsName | String        | DNS Prefix for the Openshift Master / Webconsole |   |
| numberOfNodes | Integer       | Number of Openshift Nodes to create              |   |
| image         | String        | Operating System to use. RHEL or CentOs          |   |
| rhnUser      | String        | Red Hat Network user id                          |   |
| rhnPass      | SecureString  | Red Hat Network password                         |   |
| rhnPool      | String        | Red Hat Network pool id                          |   |

```
### Output Parameters

```
| Name| Type           | Description |
| ------------- | ------------- | ------------- |
| openshift Webconsole | String       | URL of the Openshift Webconsole |
| openshift Master ssh |String | SSH String to Login at the Master |
| openshift Router Public IP | String       | Router Public IP. Needed if you want to create your own Wildcard DNS |

```
------
