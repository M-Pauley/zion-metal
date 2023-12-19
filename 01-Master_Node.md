# Build the Master Node
---

### Description:  
The master node is intended to be a combination workstation, control node, and worker node.  
Tasks for this node will be
- Install the required tools and utilities.
- Setup storage components to be consumed by k8s.
- Initalize MaaS controller.
- Commission, configure, and deploy the other nodes. 

This node will also serve to verify our initial cluster and troubleshoot any problems.  

---

## Part 1:  

🧰 A large tool requires a bigger box. 🧰  

### A Fresh Start

Get started by installing Ubuntu Server v22.04 on the workstation. I'll call mine ZionNode00 since it will eventually be a control and worker node. If you haven't installed an OS a hundred times in your life, use the 🔎googler🔍 and find an install guide or use [this one](https://ubuntu.com/download/server) and find everything you need.  

> TIP: It would be a good idea to create your Github account and SSH keys so they can be imported during installation.  

As is in good practice, run `sudo apt update` followed by `sudo apt -y upgrade`. We should probably install git first `sudo apt install -y git`, and then clone the repo `git clone https://github.com/YourUserName/MyRepo-metal/` and `cd ./MyRepo-metal`.  
  
#### Dell Utils  

If you are running old, reclaimed Dell PowerEdge servers, I highly recommend installing any firmware updates and Dell utilities for your system.

> Important Note:
>
> End of Life of Open Manage Server Administrator
>
> OpenManage Server Administrator (OMSA) will reach its End of Life status during 2024. However, OMSA will be supported until End of Support Life 
> until  2027. Dell Technologies recommends managing your PowerEdge servers by using a combination of the following Systems Management tools:
>
>    Integrated Dell Remote Access Controller (iDRAC), and
>    iDRAC Service Module (iSM) 

Well, 💩 can't support it forever. If you want to install OMSA use v11.0.1.0 and/or iSM v5.3.0.0 my scripts and guide can be found [here](./Dell/README.md) under the Dell folder.  
  
#### Other Tools  
  
🛠️ Now would be a good time to install any other tools you may want; It's your workstation after all.  
To-Do (maybe):
    - [ ] Determine required addons and CLI utilities.
    - [ ] Create Go-task tasks.
    - [ ] Figure out storage.
    - [ ] setup iSCSI and multipath storage.

---

## Part 2:

🚚 Put your junk in the trunk. 🚚

### Setup Local Storage

### Setup iSCSI and multipath storage

---
  
## Part 3:
  
👯🔗 Yes, Master. 🔗👯

### Install MaaS

Now we should have the MaaS directory we can `cd ./MaaS` followed by `./maas_install.sh`. Check out the [MaaS/README.md](./README.md) to see a breakdown of what the script is doing. You could also follow [this guide](https://maas.io/docs/fresh-installation-of-maas) to manually install MaaS.  
Access your MaaS server at *http://${API_HOST}:5240/MAAS*, where *${API_HOST}* is what you entered during MaaS installation. The script should have created a logfile in the current directory if you need it (NOTE: Any sensitive data that may be in the log is in plaintext.).  
Follow the initial MaaS setup prompts and you will eventually be met with the MaaS dashboard.  
  
If you want to setup your nodes for double-duty, now would be a good time to install *virsh* and add the host as a MaaS VM host.
  
### MaaS Setup

Configure host's network, setup host as a DHCP Server on a management network that has access to the Node BMC's. Setup a non-root user on the remote node's iDRAC and give it at least operator properties that can control server power. Also, don't forget to enable Redfish or remote IPMI.

Create cloud-init and add any MaaS commissioning scripts.

#### Commission and Deploy Nodes