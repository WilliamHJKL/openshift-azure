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

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhashnao%2Fopenshift-azure%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fhashnao%2Fopenshift-azure%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

Wait for the installation to be ready this will consist of having one infra node, one master and a number of nodes. Then go to the group that contains those machines and get the "OPENSHIFT MASTER SSH" command line that you will need for the next step.

#### From powershell CLI

```powershell
New-AzureRmResourceGroupDeployment -Name <DeploymentName> -ResourceGroupName <RessourceGroupName> -TemplateUri https://raw.githubusercontent.com/hashnao/openshift-azure/azuredeploy.json
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

