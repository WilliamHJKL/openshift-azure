# RedHat Openshift 3.2 cluster on Azure

When creating the RedHat Openshift 3.2 cluster on Azure, you will need a SSH RSA key for access. 

## Create the cluster
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

## Install Openshift with Ansible

You must use SSH Agentforwarding. 
You must register your systems into RHN and to add the proper channels.

[adminUsername@master ~]$ ./openshift-install.sh
```

------

## Parameters
### Input Parameters

| Name| Type           | Description |
| ------------- | ------------- | ------------- |
| adminUsername  | String       | Username for SSH Login and Openshift Webconsole |
|  adminPassword | SecureString | Password for the Openshift Webconsole |
| sshKeyData     | String       | Public SSH Key for the Virtual Machines |
| masterDnsName  | String       | DNS Prefix for the Openshift Master / Webconsole | 
| numberOfNodes  | Integer      | Number of Openshift Nodes to create |
| image | String | Operating System to use. RHEL or CentOs |

### Output Parameters

| Name| Type           | Description |
| ------------- | ------------- | ------------- |
| openshift Webconsole | String       | URL of the Openshift Webconsole |
| openshift Master ssh |String | SSH String to Login at the Master |
| openshift Router Public IP | String       | Router Public IP. Needed if you want to create your own Wildcard DNS |

------

This template deploys a RedHat Openshift 3.2  cluster on Azure.
This work is based on https://github.com/derdanu
