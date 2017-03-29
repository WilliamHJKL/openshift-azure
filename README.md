This work is based on https://github.com/WilliamRedHat

# RedHat Openshift 3.4 cluster on Azure

When creating the RedHat Openshift 3.4 cluster on Azure, you will need a SSH RSA key for access.
Do not forget to update rhn-username, pools, etc ...

## Create the cluster

To have OpenShift Enterprise 3.4 running on Azure, you will have to
follow 2 steps.
- First deploy the cluster with one of the following method.
- Then use Ansible to install OpenShift Container Platform 3.4

### Step 1 - Create the cluster

#### From the Azure Portal

Click on Deploy to Azure then you will be redirected to your Azure account

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flbroudoux%2Fopenshift-azure%2Frhel%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Flbroudoux%2Fopenshift-azure%2Frhel%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

Wait for the installation to be ready this will consist of having one infra node, one master and a number of nodes. Then go to the group that contains those machines and get the "OPENSHIFT MASTER SSH" command line that you will need for the next step.

#### From powershell CLI

```powershell
New-AzureRmResourceGroupDeployment -Name <DeploymentName> -ResourceGroupName <RessourceGroupName> -TemplateUri https://raw.githubusercontent.com/lbroudoux/openshift-azure/rhel/azuredeploy.json
```

#### Common parameters

Both methods implies the following parameters :

##### Input Parameters

```
| Name          | Type          | Description                                      |   |
| ------------- | ------------- | -------------                                    |   |
| adminUsername | String        | Username for SSH Login and Openshift Webconsole  |   |
| adminPassword | SecureString  | Password for the Openshift Webconsole            |   |
| sshKeyData    | String        | Public SSH Key for the Virtual Machines          |   |
| masterDnsName | String        | DNS Prefix for the Openshift Master / Webconsole |   |
| numberOfNodes | Integer       | Number of Openshift Nodes to create              |   |
| image         | String        | Operating System to use. RHEL or CentOs          |   |
| rhnUser       | String        | Red Hat Network user id                          |   |
| rhnPass       | SecureString  | Red Hat Network password                         |   |
| rhnPool       | String        | Red Hat Network pool id                          |   |

```
##### Output Parameters

```
| Name| Type           | Description |
| ------------- | ------------- | ------------- |
| openshift Webconsole | String       | URL of the Openshift Webconsole |
| openshift Master ssh |String | SSH String to Login at the Master |
| openshift Router Public IP | String       | Router Public IP. Needed if you want to create your own Wildcard DNS |

```

You're now able to go to the next step.

### Step 2 - Install Openshift with Ansible

You must connect to OpenShift master using SSH with Agent forwarding. So from your local machine:

```
[username@localmachine ~]$ ssh-add
```
so that the SSH forwarding Agent will forward the necessary data to the script that will then install OpenShift.

Then connect using your user name and the IP of master node. Example

```
[username@localmachine ~]$ ssh -A laurent@13.236.112.237
```

Then on the master you'll need to run this script :

```
[adminUsername@master ~]$ ./openshift-install.sh
```
The cluster is installed in 15 minutes or so. It creates 2 users (admin and demo with password redhat123). The admin user is set up as cluster admin. At the end of the script, you may be automatically logged in using admin user.

## Adding NFS storage

Setup scripts install a NFS server on `infranode` during the construction of Azure topology. For applications that need Persistent Volumes you will need to  run this extra script :

```
[adminUsername@master ~]$ ./create-pvs.sh
```

This is adding a bunch of Persistent volumes of different capacities for your applications.

## Adding Metrics and logging

If you need to demo the metrics or logging features of OpenShift, it is just easy to add them after the storage by running this extra script created during installation :

```
[adminUsername@master ~]$ ./openshift-services-deploy.sh
```

Metrics and logging features are respectively deployed into `openshift-infra` and `logging` projects after few minutes.
