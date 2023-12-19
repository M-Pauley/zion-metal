# Dell-specifics.

Contains scripts and information for Dell specific components of the repository.

## iDRAC Notes.

- It would behoove you to write down iDRAC MAC addresses for MaaS IPMI configration.
- iDRAC network settings should be on a network that MaaS has access to for control and power monitoring.  
- Setup an operator or administator user for MaaS to access IPMI and/or Redfish.  
- In MaaS Settings, if you don't manually define the MaaS user and password, MaaS will configure the user *maas* with a randomly generated password. If something goes wrong and you have to start over, you need to login to iDRAC and remove th *maas* account before the node will work right in a fresh MaaS Server.

## Script Description.

### utilities-install.sh
  
OpenManage System Administrator (OMSA) is EOL in 2024, use iDRAC and iSM instead.  

Intended to be used on Master Node, worker nodes can use [01-dell-01-ism.install.sh](./01-dell-01-ism.install.sh) during MaaS commissioning.  
Script installs OMSA and iSM according to the guide found at the [Dell Community Support page.](https://linux.dell.com/repo/community/openmanage/).  
Added an option to choose which one to install because of OMSA's EOL.

### 01-dell-01-ism.install.sh  
  
Cloud-init or MaaS commissioning script to install Dell's iSM utility on Dell iDRAC Worker Nodes.  
